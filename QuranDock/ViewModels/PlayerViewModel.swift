import SwiftUI
import Combine

enum ExpandedSection: Equatable {
    case surahs
    case reciters
    case customAudio
}

@MainActor
class PlayerViewModel: ObservableObject {
    @Published var surahs: [Surah] = Surah.all
    @Published var reciters: [Reciter] = Reciter.all
    @Published var selectedReciter: Reciter?
    @Published var currentSurah: Surah?
    @Published var expandedSection: ExpandedSection?
    @Published var showSpeedControls = false
    @Published var favoriteReciterIDs: Set<Int> = []
    @Published var repeatEnabled = false
    @Published var selectedMoshafIDs: [Int: Int] = [:] // reciterID -> moshafID

    // Custom tracks
    @Published var customTracks: [CustomTrack] = []
    @Published var currentCustomTrack: CustomTrack?
    @Published var isDownloadingYouTube = false
    @Published var youtubeError: String?
    @Published var pendingImport: PendingImport?

    let audioPlayer = AudioPlayerService()
    private let trackStore = CustomTrackStore.shared
    private let youtubeService = YouTubeService.shared
    private var cancellables = Set<AnyCancellable>()

    private let favoritesKey = "QuranDock.favoriteReciterIDs"
    private let moshafKey = "QuranDock.selectedMoshafIDs"

    init() {
        audioPlayer.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        audioPlayer.onTrackFinished = { [weak self] in
            self?.handleTrackFinished()
        }

        // Load favorites from UserDefaults
        if let saved = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] {
            favoriteReciterIDs = Set(saved)
        }

        // Load moshaf preferences
        if let saved = UserDefaults.standard.dictionary(forKey: moshafKey) as? [String: Int] {
            selectedMoshafIDs = Dictionary(uniqueKeysWithValues: saved.compactMap { key, val in
                guard let k = Int(key) else { return nil }
                return (k, val)
            })
        }

        // Default reciter
        selectedReciter = reciters.first(where: {
            $0.primaryMoshaf?.surahTotal == 114
        }) ?? reciters.first

        // Load custom tracks
        Task {
            customTracks = await trackStore.loadTracks()
        }
    }

    // MARK: - Moshaf Selection

    func activeMoshaf(for reciter: Reciter) -> Moshaf? {
        if let moshafID = selectedMoshafIDs[reciter.id],
           let moshaf = reciter.moshaf.first(where: { $0.id == moshafID }) {
            return moshaf
        }
        return reciter.primaryMoshaf
    }

    func selectMoshaf(_ moshaf: Moshaf, for reciter: Reciter) {
        selectedMoshafIDs[reciter.id] = moshaf.id
        let stringKeyed = Dictionary(uniqueKeysWithValues: selectedMoshafIDs.map { (String($0.key), $0.value) })
        UserDefaults.standard.set(stringKeyed, forKey: moshafKey)

        // If this reciter is currently selected, reload or stop
        if selectedReciter?.id == reciter.id {
            if let surah = currentSurah {
                if moshaf.hasSurah(surah.id) {
                    playSurah(surah)
                } else {
                    // Current surah not in new moshaf — stop playback
                    audioPlayer.stop()
                    currentSurah = nil
                }
            }
        }
    }

    // MARK: - Surah Availability

    func isSurahAvailable(_ surah: Surah) -> Bool {
        guard let reciter = selectedReciter,
              let moshaf = activeMoshaf(for: reciter) else { return false }
        return moshaf.hasSurah(surah.id)
    }

    // MARK: - Playback

    func playSurah(_ surah: Surah) {
        guard let reciter = selectedReciter,
              let moshaf = activeMoshaf(for: reciter),
              moshaf.hasSurah(surah.id) else { return }
        let padded = String(format: "%03d", surah.id)
        guard let url = URL(string: "\(moshaf.server)\(padded).mp3") else { return }
        currentCustomTrack = nil
        currentSurah = surah
        audioPlayer.loadAndPlay(url: url)
    }

    func playNextSurah() {
        guard let current = currentSurah,
              let reciter = selectedReciter,
              let moshaf = activeMoshaf(for: reciter),
              let idx = surahs.firstIndex(where: { $0.id == current.id }) else { return }
        // Skip to next available surah in this moshaf
        for i in (idx + 1)..<surahs.count {
            if moshaf.hasSurah(surahs[i].id) {
                playSurah(surahs[i])
                return
            }
        }
    }

    func playPreviousSurah() {
        guard let current = currentSurah,
              let reciter = selectedReciter,
              let moshaf = activeMoshaf(for: reciter),
              let idx = surahs.firstIndex(where: { $0.id == current.id }) else { return }
        // Skip to previous available surah in this moshaf
        for i in stride(from: idx - 1, through: 0, by: -1) {
            if moshaf.hasSurah(surahs[i].id) {
                playSurah(surahs[i])
                return
            }
        }
    }

    func selectReciter(_ reciter: Reciter) {
        selectedReciter = reciter
        if let surah = currentSurah {
            playSurah(surah)
        }
    }

    // MARK: - Custom Track Playback

    func playCustomTrack(_ track: CustomTrack) {
        guard let url = track.fileURL else { return }
        currentSurah = nil
        currentCustomTrack = track
        audioPlayer.loadAndPlay(url: url)
    }

    func playNextCustomTrack() {
        guard let current = currentCustomTrack,
              let idx = customTracks.firstIndex(where: { $0.id == current.id }),
              idx + 1 < customTracks.count else { return }
        playCustomTrack(customTracks[idx + 1])
    }

    func playPreviousCustomTrack() {
        guard let current = currentCustomTrack,
              let idx = customTracks.firstIndex(where: { $0.id == current.id }),
              idx > 0 else { return }
        playCustomTrack(customTracks[idx - 1])
    }

    func playNext() {
        if currentCustomTrack != nil {
            playNextCustomTrack()
        } else {
            playNextSurah()
        }
    }

    func playPrevious() {
        if currentCustomTrack != nil {
            playPreviousCustomTrack()
        } else {
            playPreviousSurah()
        }
    }

    // MARK: - Custom Track Management

    func addCustomTrackFromFile(url: URL) {
        Task {
            do {
                let fileName = try await trackStore.copyFileToDownloads(from: url)
                let title = url.deletingPathExtension().lastPathComponent
                pendingImport = PendingImport(
                    fileName: fileName,
                    defaultTitle: title,
                    source: .localFile(originalName: url.lastPathComponent)
                )
            } catch {
                print("[CustomTrack] Failed to import file: \(error.localizedDescription)")
            }
        }
    }

    func addCustomTrackFromYouTube(urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard youtubeService.isValidYouTubeURL(trimmed) else {
            youtubeError = "Invalid YouTube URL."
            return
        }

        isDownloadingYouTube = true
        youtubeError = nil

        Task {
            do {
                let result = try await youtubeService.downloadAudio(from: trimmed)
                isDownloadingYouTube = false
                pendingImport = PendingImport(
                    fileName: result.fileName,
                    defaultTitle: result.title,
                    source: .youtube(url: trimmed)
                )
            } catch {
                youtubeError = error.localizedDescription
                isDownloadingYouTube = false
            }
        }
    }

    func savePendingTrack(title: String, reciterName: String?, surahId: Int?, qiraah: Qiraah?) {
        guard let pending = pendingImport else { return }
        let track = CustomTrack(
            title: title,
            fileName: pending.fileName,
            source: pending.source,
            reciterName: reciterName,
            surahId: surahId,
            qiraah: qiraah
        )
        customTracks.insert(track, at: 0)
        pendingImport = nil
        Task { await trackStore.saveTracks(customTracks) }
    }

    func cancelPendingImport() {
        guard let pending = pendingImport else { return }
        Task { await trackStore.deleteFile(named: pending.fileName) }
        pendingImport = nil
    }

    func removeCustomTrack(_ track: CustomTrack) {
        // Stop playback if this track is playing
        if currentCustomTrack?.id == track.id {
            audioPlayer.stop()
            currentCustomTrack = nil
        }

        customTracks.removeAll { $0.id == track.id }

        Task {
            await trackStore.deleteFile(named: track.fileName)
            await trackStore.saveTracks(customTracks)
        }
    }

    // MARK: - Repeat

    func toggleRepeat() {
        repeatEnabled.toggle()
    }

    private func handleTrackFinished() {
        if repeatEnabled {
            if let track = currentCustomTrack {
                playCustomTrack(track)
            } else if let surah = currentSurah {
                playSurah(surah)
            }
        } else {
            if currentCustomTrack != nil {
                playNextCustomTrack()
            } else {
                playNextSurah()
            }
        }
    }

    // MARK: - Section Toggle

    func toggleSection(_ section: ExpandedSection) {
        withAnimation(.smooth(duration: 0.3)) {
            expandedSection = expandedSection == section ? nil : section
        }
    }

    var isExpanded: Bool {
        expandedSection != nil
    }

    // MARK: - Favorites

    func toggleFavorite(_ reciter: Reciter) {
        if favoriteReciterIDs.contains(reciter.id) {
            favoriteReciterIDs.remove(reciter.id)
        } else {
            favoriteReciterIDs.insert(reciter.id)
        }
        UserDefaults.standard.set(Array(favoriteReciterIDs), forKey: favoritesKey)
    }

    func isFavorite(_ reciter: Reciter) -> Bool {
        favoriteReciterIDs.contains(reciter.id)
    }
}

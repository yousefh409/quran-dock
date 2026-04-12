import SwiftUI
import Combine

enum ExpandedSection: Equatable {
    case surahs
    case reciters
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

    let audioPlayer = AudioPlayerService()
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

    // MARK: - Repeat

    func toggleRepeat() {
        repeatEnabled.toggle()
    }

    private func handleTrackFinished() {
        if repeatEnabled, let surah = currentSurah {
            playSurah(surah)
        } else {
            playNextSurah()
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

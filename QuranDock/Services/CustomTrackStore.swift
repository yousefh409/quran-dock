import Foundation

actor CustomTrackStore {
    static let shared = CustomTrackStore()

    private let fileManager = FileManager.default

    // MARK: - Directories

    static var downloadsDirectory: URL? {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = appSupport.appendingPathComponent("QuranDock/Downloads", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var tracksFileURL: URL? {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = appSupport.appendingPathComponent("QuranDock", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom_tracks.json")
    }

    // MARK: - CRUD

    func loadTracks() -> [CustomTrack] {
        guard let url = tracksFileURL,
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([CustomTrack].self, from: data)) ?? []
    }

    func saveTracks(_ tracks: [CustomTrack]) {
        guard let url = tracksFileURL,
              let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func copyFileToDownloads(from sourceURL: URL) throws -> String {
        guard let dir = Self.downloadsDirectory else {
            throw CustomTrackError.directoryUnavailable
        }
        let uniqueName = "\(UUID().uuidString)_\(sourceURL.lastPathComponent)"
        let destURL = dir.appendingPathComponent(uniqueName)
        try fileManager.copyItem(at: sourceURL, to: destURL)
        return uniqueName
    }

    func deleteFile(named fileName: String) {
        guard let dir = Self.downloadsDirectory else { return }
        let fileURL = dir.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }
}

enum CustomTrackError: LocalizedError {
    case directoryUnavailable
    case fileCopyFailed
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .directoryUnavailable: return "Could not access storage directory."
        case .fileCopyFailed: return "Failed to copy the audio file."
        case .downloadFailed(let reason): return "Download failed: \(reason)"
        }
    }
}

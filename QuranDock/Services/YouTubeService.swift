import Foundation

actor YouTubeService {
    static let shared = YouTubeService()

    private let fileManager = FileManager.default

    // MARK: - URL Validation

    nonisolated func isValidYouTubeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    // MARK: - yt-dlp Binary Resolution

    private func ytDlpPath() -> String? {
        // 1. Check bundled binary
        if let bundled = Bundle.main.url(forResource: "yt-dlp", withExtension: nil) {
            let path = bundled.path
            // Ensure executable
            if !fileManager.isExecutableFile(atPath: path) {
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
            }
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        // 2. Bundled binary in Resources with _macos suffix
        if let bundled = Bundle.main.url(forResource: "yt-dlp_macos", withExtension: nil) {
            let path = bundled.path
            if !fileManager.isExecutableFile(atPath: path) {
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
            }
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        // 3. Fall back to system-installed yt-dlp
        let systemPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        for path in systemPaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        return nil
    }

    // MARK: - Fetch Title

    func fetchTitle(for urlString: String) async throws -> String {
        guard let binary = ytDlpPath() else {
            throw YouTubeError.ytDlpNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = ["--print", "title", "--no-download", urlString]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw YouTubeError.fetchTitleFailed
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let title = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return title ?? "Unknown Title"
    }

    // MARK: - Download Audio

    func downloadAudio(from urlString: String) async throws -> (fileName: String, title: String) {
        guard let binary = ytDlpPath() else {
            throw YouTubeError.ytDlpNotFound
        }

        guard let downloadsDir = CustomTrackStore.downloadsDirectory else {
            throw YouTubeError.directoryUnavailable
        }

        let outputID = UUID().uuidString
        let outputTemplate = downloadsDir.appendingPathComponent("\(outputID).%(ext)s").path

        // Step 1: Download audio-only (no forced mp3 conversion — avoids ffmpeg dependency)
        // Use --print to get both title and final filepath in one pass
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = [
            "-x",                                     // extract audio
            "--print", "%(title)s",                    // print title to stdout
            "--print", "after_move:%(filepath)s",      // print final file path to stdout
            "-o", outputTemplate,
            "--no-progress",                           // keep stdout clean
            urlString
        ]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw YouTubeError.downloadFailed(errMsg)
        }

        // Parse stdout: first line = title, second line = filepath
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let outputLines = (String(data: outData, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        let title = outputLines.first ?? "YouTube Audio"

        // Check if yt-dlp told us the exact filepath
        if outputLines.count >= 2 {
            let filePath = outputLines[1]
            let fileURL = URL(fileURLWithPath: filePath)
            if fileManager.fileExists(atPath: filePath) {
                return (fileName: fileURL.lastPathComponent, title: title)
            }
        }

        // Fallback: scan downloads directory for any file with our UUID prefix
        let contents = (try? fileManager.contentsOfDirectory(atPath: downloadsDir.path)) ?? []
        if let match = contents.first(where: { $0.hasPrefix(outputID) }) {
            return (fileName: match, title: title)
        }

        throw YouTubeError.downloadFailed("Downloaded file not found.")
    }
}

enum YouTubeError: LocalizedError {
    case ytDlpNotFound
    case fetchTitleFailed
    case directoryUnavailable
    case downloadFailed(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .ytDlpNotFound:
            return "yt-dlp not found. Install it via Homebrew: brew install yt-dlp"
        case .fetchTitleFailed:
            return "Could not fetch video title."
        case .directoryUnavailable:
            return "Could not access storage directory."
        case .downloadFailed(let msg):
            return "Download failed: \(msg)"
        case .invalidURL:
            return "Invalid YouTube URL."
        }
    }
}

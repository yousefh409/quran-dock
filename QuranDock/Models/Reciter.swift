import Foundation
import AppKit

struct Reciter: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let letter: String
    let moshaf: [Moshaf]

    var primaryMoshaf: Moshaf? {
        moshaf.first(where: { $0.surahTotal == 114 }) ?? moshaf.first
    }

    func audioURL(for surahNumber: Int) -> URL? {
        guard let m = primaryMoshaf else { return nil }
        let padded = String(format: "%03d", surahNumber)
        return URL(string: "\(m.server)\(padded).mp3")
    }

    func hasSurah(_ surahNumber: Int) -> Bool {
        guard let m = primaryMoshaf else { return false }
        return m.surahListArray.contains(surahNumber)
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var bundledPhoto: NSImage? {
        guard let url = Bundle.main.url(
            forResource: "\(id)",
            withExtension: "jpg"
        ) else { return nil }
        return NSImage(contentsOf: url)
    }
}

struct Moshaf: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let server: String
    let surahTotal: Int
    let moshafType: Int
    let surahList: String

    enum CodingKeys: String, CodingKey {
        case id, name, server
        case surahTotal = "surah_total"
        case moshafType = "moshaf_type"
        case surahList = "surah_list"
    }

    var surahListArray: [Int] {
        surahList.split(separator: ",").compactMap { Int($0) }
    }

    func hasSurah(_ surahNumber: Int) -> Bool {
        surahListArray.contains(surahNumber)
    }

    /// Shorter display name: extracts the rewaya/style part
    var shortName: String {
        // Names like "Rewayat Hafs A'n Assem - Murattal" -> "Hafs - Murattal"
        // Names like "Almusshaf Al Mojawwad - Almusshaf Al Mojawwad" -> "Al Mojawwad"
        let parts = name.split(separator: " - ", maxSplits: 1)
        if parts.count == 2 {
            let rewaya = String(parts[0])
            let style = String(parts[1])
            // Clean up rewaya part
            let cleanRewaya = rewaya
                .replacingOccurrences(of: "Rewayat ", with: "")
                .replacingOccurrences(of: " A'n Assem", with: "")
                .replacingOccurrences(of: " A'n Nafi'", with: "")
                .replacingOccurrences(of: "Almusshaf ", with: "")
            return "\(cleanRewaya) · \(style)"
        }
        return name
    }
}

struct RecitersResponse: Codable {
    let reciters: [Reciter]
}

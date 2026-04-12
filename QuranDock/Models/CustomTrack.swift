import Foundation

// MARK: - Track Source

enum TrackSource: Codable, Hashable {
    case localFile(originalName: String)
    case youtube(url: String)

    var label: String {
        switch self {
        case .localFile: return "Local File"
        case .youtube: return "YouTube"
        }
    }

    var iconName: String {
        switch self {
        case .localFile: return "doc.fill"
        case .youtube: return "play.rectangle.fill"
        }
    }
}

// MARK: - Qira'ah

enum Qiraah: String, Codable, CaseIterable, Identifiable {
    case hafs = "Hafs 'an 'Asim"
    case warsh = "Warsh 'an Nafi'"
    case qalun = "Qalun 'an Nafi'"
    case duri = "Al-Duri 'an Abu 'Amr"
    case susi = "Al-Susi 'an Abu 'Amr"
    case shubah = "Shu'bah 'an 'Asim"
    case ibnKathir = "Ibn Kathir"
    case kisai = "Al-Kisai"
    case abuJafar = "Abu Ja'far"
    case khalaf = "Khalaf al-'Ashir"

    var id: String { rawValue }
}

// MARK: - Pending Import

struct PendingImport {
    let fileName: String
    let defaultTitle: String
    let source: TrackSource
}

// MARK: - Custom Track

struct CustomTrack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    let fileName: String
    let source: TrackSource
    let dateAdded: Date
    var reciterName: String?
    var surahId: Int?
    var qiraah: Qiraah?

    var fileURL: URL? {
        let dir = CustomTrackStore.downloadsDirectory
        return dir?.appendingPathComponent(fileName)
    }

    var displayReciter: String {
        if let name = reciterName, !name.isEmpty {
            return name
        }
        return source.label
    }

    var displayTitle: String {
        if let surahId = surahId,
           let surah = Surah.all.first(where: { $0.id == surahId }) {
            return surah.nameArabic
        }
        return title
    }

    var displaySubtitle: String {
        var parts: [String] = []
        parts.append(displayReciter)
        if let q = qiraah {
            parts.append(q.rawValue)
        }
        return parts.joined(separator: " · ")
    }

    init(title: String, fileName: String, source: TrackSource,
         reciterName: String? = nil, surahId: Int? = nil, qiraah: Qiraah? = nil) {
        self.id = UUID()
        self.title = title
        self.fileName = fileName
        self.source = source
        self.dateAdded = Date()
        self.reciterName = reciterName
        self.surahId = surahId
        self.qiraah = qiraah
    }
}

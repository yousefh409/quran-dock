import Foundation

struct Surah: Identifiable, Codable, Hashable {
    let id: Int
    let nameArabic: String
    let nameSimple: String
    let nameTranslation: String
    let versesCount: Int
    let revelationPlace: String
}

// MARK: - Quran.com API Response

struct QuranComChaptersResponse: Codable {
    let chapters: [QuranComChapter]
}

struct QuranComChapter: Codable {
    let id: Int
    let nameArabic: String
    let nameSimple: String
    let translatedName: TranslatedName
    let versesCount: Int
    let revelationPlace: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameArabic = "name_arabic"
        case nameSimple = "name_simple"
        case translatedName = "translated_name"
        case versesCount = "verses_count"
        case revelationPlace = "revelation_place"
    }

    func toSurah() -> Surah {
        Surah(
            id: id,
            nameArabic: nameArabic,
            nameSimple: nameSimple,
            nameTranslation: translatedName.name,
            versesCount: versesCount,
            revelationPlace: revelationPlace
        )
    }
}

struct TranslatedName: Codable {
    let name: String
}

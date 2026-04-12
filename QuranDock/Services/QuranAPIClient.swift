import Foundation

actor QuranAPIClient {
    static let shared = QuranAPIClient()

    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let cache = CacheManager.shared

    // MARK: - Surahs

    func fetchSurahs(forceRefresh: Bool = false) async throws -> [Surah] {
        if !forceRefresh, let cached: [Surah] = await cache.load([Surah].self, forKey: "surahs") {
            return cached
        }

        let url = URL(string: "\(AppConstants.quranComBaseURL)/chapters?language=en")!
        print("[API] Fetching surahs from \(url)")
        let (data, response) = try await session.data(from: url)
        print("[API] Surahs response: \(data.count) bytes, status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        let decoded = try decoder.decode(QuranComChaptersResponse.self, from: data)
        let surahs = decoded.chapters.map { $0.toSurah() }
        print("[API] Parsed \(surahs.count) surahs")

        try? await cache.save(surahs, forKey: "surahs")
        return surahs
    }

    // MARK: - Reciters

    func fetchReciters(forceRefresh: Bool = false) async throws -> [Reciter] {
        if !forceRefresh, let cached: [Reciter] = await cache.load([Reciter].self, forKey: "reciters") {
            return cached
        }

        let url = URL(string: "\(AppConstants.mp3QuranBaseURL)/reciters?language=eng")!
        print("[API] Fetching reciters from \(url)")
        let (data, resp) = try await session.data(from: url)
        print("[API] Reciters response: \(data.count) bytes, status: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
        let response = try decoder.decode(RecitersResponse.self, from: data)

        // Sort: reciters with full Quran first, then by name
        let sorted = response.reciters.sorted { a, b in
            let aFull = a.primaryMoshaf?.surahTotal == 114
            let bFull = b.primaryMoshaf?.surahTotal == 114
            if aFull != bFull { return aFull }
            return a.name < b.name
        }

        try? await cache.save(sorted, forKey: "reciters")
        return sorted
    }
}

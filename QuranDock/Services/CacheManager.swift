import Foundation

actor CacheManager {
    static let shared = CacheManager()

    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("QuranDock/Cache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func save<T: Codable>(_ data: T, forKey key: String) throws {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        let wrapper = CacheWrapper(data: data, cachedAt: Date())
        let encoded = try JSONEncoder().encode(wrapper)
        try encoded.write(to: url, options: Data.WritingOptions.atomic)
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String, ttl: TimeInterval = AppConstants.cacheTTL) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let wrapper = try? JSONDecoder().decode(CacheWrapper<T>.self, from: data) else { return nil }

        if Date().timeIntervalSince(wrapper.cachedAt) > ttl {
            return nil // expired
        }
        return wrapper.data
    }

    func hasFreshCache(forKey key: String, ttl: TimeInterval = AppConstants.cacheTTL) -> Bool {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(CacheTimestamp.self, from: data) else { return false }
        return Date().timeIntervalSince(wrapper.cachedAt) <= ttl
    }
}

private struct CacheWrapper<T: Codable>: Codable {
    let data: T
    let cachedAt: Date
}

private struct CacheTimestamp: Codable {
    let cachedAt: Date
}

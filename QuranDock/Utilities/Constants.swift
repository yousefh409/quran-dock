import SwiftUI

enum AppConstants {
    static let mp3QuranBaseURL = "https://www.mp3quran.net/api/v3"
    static let quranComBaseURL = "https://api.quran.com/api/v4"

    static let popoverWidth: CGFloat = 440
    static let expandedListHeight: CGFloat = 420

    // MARK: - Colors
    static let accentColor = Color(red: 0.13, green: 0.55, blue: 0.47)
    static let accentColorLight = Color(red: 0.18, green: 0.77, blue: 0.63)

    // MARK: - Typography
    static let amiriQuranFontName = "Amiri Quran"
    static let amiriQuranFileName = "AmiriQuran-Regular"

    // MARK: - Playback
    static let skipInterval: TimeInterval = 15

    // MARK: - Cache
    static let cacheTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // MARK: - Corner Radii
    static let avatarRadius: CGFloat = 14
    static let badgeRadius: CGFloat = 8
    static let cardRadius: CGFloat = 10
    static let buttonRadius: CGFloat = 10
}

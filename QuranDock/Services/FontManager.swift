import CoreText
import Foundation

enum FontManager {
    static func registerFonts() {
        guard let fontURL = Bundle.main.url(
            forResource: AppConstants.amiriQuranFileName,
            withExtension: "ttf"
        ) else {
            print("[FontManager] AmiriQuran-Regular.ttf not found in bundle")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            let desc = error?.takeRetainedValue().localizedDescription ?? "Unknown"
            print("[FontManager] Failed to register font: \(desc)")
        }
    }
}

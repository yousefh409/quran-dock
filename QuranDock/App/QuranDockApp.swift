import SwiftUI

@main
struct QuranDockApp: App {
    @StateObject private var viewModel = PlayerViewModel()

    init() {
        FontManager.registerFonts()
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    NSApplication.shared.setActivationPolicy(.accessory)
                }
        } label: {
            Image(systemName: "book.closed.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

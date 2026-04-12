import SwiftUI
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 0) {
            mainContent
        }
        .frame(width: AppConstants.popoverWidth)
        .background(
            VisualEffectBlur(
                material: .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
        )
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                NowPlayingView(isCompact: viewModel.isExpanded)

                if viewModel.expandedSection == nil {
                    settingsMenu
                }
            }

            // Thin separator
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            segmentedTabs

            if let section = viewModel.expandedSection {
                expandedContent(for: section)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer(minLength: 0)
        }
        .animation(.smooth(duration: 0.3), value: viewModel.expandedSection)
    }

    // MARK: - Segmented Tabs

    private var segmentedTabs: some View {
        HStack(spacing: 0) {
            segmentTab("Reciters", icon: "person.2.fill", section: .reciters)

            // Vertical divider
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5, height: 18)

            segmentTab("Surahs", icon: "book.fill", section: .surahs)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5, height: 18)

            segmentTab("My Audio", icon: "music.note.list", section: .customAudio)
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func segmentTab(_ title: String, icon: String, section: ExpandedSection) -> some View {
        let isActive = viewModel.expandedSection == section
        return Button {
            withAnimation(.smooth(duration: 0.3)) {
                if isActive {
                    viewModel.expandedSection = nil
                } else {
                    viewModel.expandedSection = section
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                }
            )
            .foregroundStyle(isActive ? AppConstants.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Menu

    private var settingsMenu: some View {
        Menu {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                    }
                }

            Divider()

            Button("Quit QuranDock") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "gearshape")
                .resizable()
                .frame(width: 12, height: 12)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .padding(10)
        .tint(Color(nsColor: .systemGray).opacity(0.4))
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContent(for section: ExpandedSection) -> some View {
        switch section {
        case .surahs:
            SurahListView()
        case .reciters:
            ReciterListView()
        case .customAudio:
            CustomAudioView()
        }
    }
}

import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    var isCompact: Bool = false

    /// Whether anything is currently loaded (surah or custom track)
    private var hasTrack: Bool {
        viewModel.currentSurah != nil || viewModel.currentCustomTrack != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if isCompact {
                compactLayout
                    .transition(.opacity)
            } else {
                fullLayout
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.3), value: isCompact)
    }

    // MARK: - Full Layout (centered, minimal)

    private var fullLayout: some View {
        VStack(spacing: 10) {
            // Centered track info
            VStack(spacing: 4) {
                if let track = viewModel.currentCustomTrack {
                    Text(track.displayTitle)
                        .font(track.surahId != nil
                            ? .custom(AppConstants.amiriQuranFontName, size: 28)
                            : .system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(track.displaySubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let surah = viewModel.currentSurah {
                    Text(surah.nameArabic)
                        .font(.custom(AppConstants.amiriQuranFontName, size: 28))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(surah.nameSimple)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Quran Dock")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)

                    Text("Select a surah to begin")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                if viewModel.currentCustomTrack == nil, let reciter = viewModel.selectedReciter {
                    HStack(spacing: 5) {
                        Text(reciter.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppConstants.accentColor.opacity(0.8))
                            .lineLimit(1)

                        if reciter.moshaf.count > 1 {
                            moshafPicker(for: reciter)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Seek bar
            if hasTrack {
                SeekBarView()
                    .transition(.opacity)
            }

            // Speed controls
            if viewModel.showSpeedControls {
                SpeedControlView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Transport controls
            fullTransportControls
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    AppConstants.accentColor.opacity(hasTrack ? 0.05 : 0),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.smooth(duration: 0.25), value: viewModel.showSpeedControls)
    }

    // MARK: - Compact Layout (inline)

    private var compactLayout: some View {
        HStack(spacing: 10) {
            // Small track info — tappable to collapse
            VStack(alignment: .leading, spacing: 1) {
                if let track = viewModel.currentCustomTrack {
                    Text(track.displayTitle)
                        .font(track.surahId != nil
                            ? .custom(AppConstants.amiriQuranFontName, size: 14)
                            : .system(size: 12, weight: .medium))
                        .lineLimit(1)

                    Text(track.displaySubtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let surah = viewModel.currentSurah {
                    Text(surah.nameArabic)
                        .font(.custom(AppConstants.amiriQuranFontName, size: 14))
                        .lineLimit(1)

                    Text(surah.nameSimple)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Quran Dock")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.smooth(duration: 0.3)) {
                    viewModel.expandedSection = nil
                }
            }

            Spacer()

            compactControls
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Compact Controls

    private var compactControls: some View {
        HStack(spacing: 14) {
            Button { viewModel.playPrevious() } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button { viewModel.audioPlayer.togglePlayPause() } label: {
                if viewModel.audioPlayer.isLoading {
                    ProgressView().scaleEffect(0.5)
                        .frame(width: 24, height: 24)
                } else {
                    ZStack {
                        Circle()
                            .fill(AppConstants.accentColor)
                            .frame(width: 24, height: 24)

                        Image(systemName: viewModel.audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: viewModel.audioPlayer.isPlaying ? 0 : 0.5)
                    }
                }
            }
            .buttonStyle(.plain)

            Button { viewModel.playNext() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Full Transport Controls

    private var fullTransportControls: some View {
        HStack(spacing: 0) {
            // Repeat button
            Button { viewModel.toggleRepeat() } label: {
                Image(systemName: viewModel.repeatEnabled ? "repeat.1" : "repeat")
                    .font(.system(size: 14, weight: viewModel.repeatEnabled ? .semibold : .regular))
                    .foregroundStyle(viewModel.repeatEnabled ? AppConstants.accentColor : .secondary.opacity(0.4))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help(viewModel.repeatEnabled ? "Repeat: On" : "Repeat: Off")

            Spacer()

            // Center controls
            HStack(spacing: 24) {
                Button { viewModel.playPrevious() } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.primary.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!hasTrack)

                Button { viewModel.audioPlayer.togglePlayPause() } label: {
                    if viewModel.audioPlayer.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 44, height: 44)
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppConstants.accentColor)
                                .frame(width: 44, height: 44)
                                .shadow(color: AppConstants.accentColor.opacity(0.3), radius: 10, x: 0, y: 3)

                            Image(systemName: viewModel.audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: viewModel.audioPlayer.isPlaying ? 0 : 1.5)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!hasTrack)

                Button { viewModel.playNext() } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.primary.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!hasTrack)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 32, height: 32)
        }
    }

    // MARK: - Reciter Avatar

    private func reciterAvatar(_ reciter: Reciter) -> some View {
        Group {
            if let photo = reciter.bundledPhoto {
                Image(nsImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(AppConstants.accentColor.opacity(0.15), lineWidth: 0.5)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppConstants.accentColor.opacity(0.2), AppConstants.accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(reciter.initials)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppConstants.accentColor)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(AppConstants.accentColor.opacity(0.15), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - Moshaf Picker

    private func moshafPicker(for reciter: Reciter) -> some View {
        let active = viewModel.activeMoshaf(for: reciter)
        return Menu {
            ForEach(reciter.moshaf) { m in
                Button {
                    viewModel.selectMoshaf(m, for: reciter)
                } label: {
                    HStack {
                        Text(m.shortName)
                        if m.id == active?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(active?.shortName ?? "Recording")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppConstants.accentColor.opacity(0.7))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 6))
                    .foregroundStyle(AppConstants.accentColor.opacity(0.5))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(AppConstants.accentColor.opacity(0.08))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

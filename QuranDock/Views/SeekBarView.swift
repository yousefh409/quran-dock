import SwiftUI
import AVFoundation

struct SeekBarView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @State private var isSeeking = false
    @State private var seekValue: Double = 0
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 6) {
            // Thin progress track
            GeometryReader { geo in
                let width = geo.size.width
                let fillWidth = width * CGFloat(seekValue)

                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 3)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppConstants.accentColor)
                        .frame(width: max(0, fillWidth), height: 3)

                    // Knob (only on hover/seek)
                    Circle()
                        .fill(.white)
                        .frame(width: isHovering ? 10 : 8, height: isHovering ? 10 : 8)
                        .shadow(color: AppConstants.accentColor.opacity(0.4), radius: 4, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: max(0, fillWidth - (isHovering ? 5 : 4)))
                        .opacity(isHovering || isSeeking ? 1 : 0)
                }
                .frame(height: 12)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isSeeking = true
                            seekValue = min(max(Double(value.location.x / width), 0), 1)
                        }
                        .onEnded { _ in
                            let targetTime = seekValue * viewModel.audioPlayer.duration
                            viewModel.audioPlayer.seek(to: targetTime)
                            isSeeking = false
                        }
                )
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering }
                }
            }
            .frame(height: 12)
            .onChange(of: viewModel.audioPlayer.progress) { newValue in
                if !isSeeking {
                    seekValue = newValue
                }
            }

            // Time row
            HStack {
                Text(CMTime(seconds: viewModel.audioPlayer.currentTime,
                            preferredTimescale: 600).formattedString)
                    .foregroundStyle(.tertiary)

                Spacer()

                // Speed button
                Button {
                    withAnimation(.smooth(duration: 0.25)) {
                        viewModel.showSpeedControls.toggle()
                    }
                } label: {
                    Text(speedLabel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(viewModel.showSpeedControls ? AppConstants.accentColor.opacity(0.1) : Color.primary.opacity(0.04))
                        )
                        .foregroundStyle(viewModel.showSpeedControls ? AppConstants.accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(CMTime(seconds: viewModel.audioPlayer.duration,
                            preferredTimescale: 600).formattedString)
                    .foregroundStyle(.tertiary)
            }
            .font(.system(size: 9, design: .monospaced))
        }
    }

    private var speedLabel: String {
        let s = viewModel.audioPlayer.speed
        if let preset = PlaybackSpeed.closest(to: s) {
            return preset.label
        }
        return String(format: "%.1fx", s)
    }
}

import SwiftUI

struct SpeedControlView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @State private var sliderValue: Float = 1.0

    var body: some View {
        VStack(spacing: 8) {
            // Preset buttons
            HStack(spacing: 4) {
                ForEach(PlaybackSpeed.allCases) { speed in
                    let isActive = PlaybackSpeed.closest(to: viewModel.audioPlayer.speed) == speed
                    Button {
                        viewModel.audioPlayer.setPresetSpeed(speed)
                        sliderValue = speed.rawValue
                    } label: {
                        Text(speed.label)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isActive ? AppConstants.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                            )
                            .foregroundStyle(isActive ? AppConstants.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Continuous slider
            HStack(spacing: 6) {
                Text("0.5x")
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)

                Slider(value: $sliderValue, in: 0.5...2.0, step: 0.05)
                    .tint(AppConstants.accentColor)
                    .controlSize(.mini)
                    .onChange(of: sliderValue) { newValue in
                        viewModel.audioPlayer.setSpeed(newValue)
                    }

                Text("2x")
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)

                Text(String(format: "%.2fx", viewModel.audioPlayer.speed))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppConstants.accentColor)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
        .padding(.horizontal, 2)
        .onAppear {
            sliderValue = viewModel.audioPlayer.speed
        }
    }
}

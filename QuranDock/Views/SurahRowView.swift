import SwiftUI

struct SurahRowView: View {
    let surah: Surah
    let isPlaying: Bool
    var isAvailable: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            // Playing accent bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isPlaying ? AppConstants.accentColor : Color.clear)
                .frame(width: 3, height: 28)

            // Diamond number badge
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isPlaying
                          ? AppConstants.accentColor.opacity(0.12)
                          : Color.primary.opacity(isAvailable ? 0.04 : 0.02))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(45))

                Text("\(surah.id)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(isPlaying ? AppConstants.accentColor : (isAvailable ? .secondary : Color.secondary.opacity(0.4)))
            }
            .frame(width: 34, height: 34)

            // English info
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameSimple)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isPlaying ? AppConstants.accentColor : (isAvailable ? .primary : Color.secondary.opacity(0.5)))

                Text("\(surah.versesCount) Ayahs")
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary.opacity(isAvailable ? 0.7 : 0.3))
            }

            Spacer()

            // Arabic name
            Text(surah.nameArabic)
                .font(.custom(AppConstants.amiriQuranFontName, size: 17))
                .foregroundColor(isPlaying ? AppConstants.accentColor : (isAvailable ? .primary : Color.secondary.opacity(0.4)))

            // Playing indicator
            if isPlaying {
                PlayingBarsView()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isPlaying ? AppConstants.accentColor.opacity(0.05) : Color.clear)
        )
        .padding(.horizontal, 4)
        .opacity(isAvailable ? 1 : 0.5)
    }
}

// MARK: - Animated Playing Bars

struct PlayingBarsView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppConstants.accentColor)
                    .frame(width: 2.5, height: animating ? barHeight(for: i) : 4)
                    .animation(
                        .easeInOut(duration: duration(for: i))
                            .repeatForever(autoreverses: true),
                        value: animating
                    )
            }
        }
        .frame(width: 14, height: 14)
        .onAppear { animating = true }
    }

    private func barHeight(for index: Int) -> CGFloat {
        switch index {
        case 0: return 10
        case 1: return 14
        default: return 8
        }
    }

    private func duration(for index: Int) -> Double {
        switch index {
        case 0: return 0.5
        case 1: return 0.35
        default: return 0.45
        }
    }
}

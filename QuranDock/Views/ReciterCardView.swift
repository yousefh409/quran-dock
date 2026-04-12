import SwiftUI

struct ReciterCardView: View {
    let reciter: Reciter
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Photo or initials — circle avatar
            if let photo = reciter.bundledPhoto {
                Image(nsImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? AppConstants.accentColor.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            } else {
                Circle()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [AppConstants.accentColor, AppConstants.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [AppConstants.accentColor.opacity(0.12), AppConstants.accentColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(reciter.initials)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? .white : AppConstants.accentColor)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? AppConstants.accentColor.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(reciter.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? AppConstants.accentColor : .primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let m = reciter.primaryMoshaf {
                        Text("\(m.surahTotal) surahs")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    if reciter.moshaf.count > 1 {
                        Text("· \(reciter.moshaf.count) recordings")
                            .font(.system(size: 10))
                            .foregroundStyle(AppConstants.accentColor.opacity(0.5))
                    }
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppConstants.accentColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? AppConstants.accentColor.opacity(0.06) : Color.clear)
        )
    }
}

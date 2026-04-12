import SwiftUI

struct SurahListView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @StateObject private var listVM = SurahListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                TextField("Search surahs...", text: $listVM.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !listVM.searchText.isEmpty {
                    Button {
                        listVM.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 4)

            // List
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(listVM.filteredSurahs(from: viewModel.surahs)) { surah in
                        let available = viewModel.isSurahAvailable(surah)
                        SurahRowView(
                            surah: surah,
                            isPlaying: viewModel.currentSurah?.id == surah.id,
                            isAvailable: available
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if available {
                                viewModel.playSurah(surah)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: AppConstants.expandedListHeight)
        }
    }
}

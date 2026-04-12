import SwiftUI

struct ReciterListView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @StateObject private var listVM = ReciterListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                TextField("Search reciters...", text: $listVM.searchText)
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
                LazyVStack(spacing: 2) {
                    // Favorites section
                    if listVM.searchText.isEmpty && !viewModel.favoriteReciterIDs.isEmpty {
                        let favorites = viewModel.reciters.filter { viewModel.isFavorite($0) }
                        if !favorites.isEmpty {
                            HStack {
                                Text("Favorites")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppConstants.accentColor.opacity(0.6))
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 6)
                            .padding(.bottom, 2)

                            ForEach(favorites) { reciter in
                                reciterRow(reciter)
                            }

                            // Divider
                            Rectangle()
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)

                            HStack {
                                Text("All Reciters")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary.opacity(0.6))
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 2)
                        }
                    }

                    ForEach(listVM.filteredReciters(from: viewModel.reciters)) { reciter in
                        reciterRow(reciter)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: AppConstants.expandedListHeight)
        }
    }

    private func reciterRow(_ reciter: Reciter) -> some View {
        HStack(spacing: 0) {
            ReciterCardView(
                reciter: reciter,
                isSelected: viewModel.selectedReciter?.id == reciter.id
            )
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectReciter(reciter)
            }

            Button {
                viewModel.toggleFavorite(reciter)
            } label: {
                Image(systemName: viewModel.isFavorite(reciter) ? "heart.fill" : "heart")
                    .font(.system(size: 12))
                    .foregroundStyle(viewModel.isFavorite(reciter) ? .red : .secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
    }
}

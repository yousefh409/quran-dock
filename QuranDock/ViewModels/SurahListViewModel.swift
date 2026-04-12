import SwiftUI

@MainActor
class SurahListViewModel: ObservableObject {
    @Published var searchText = ""

    func filteredSurahs(from surahs: [Surah]) -> [Surah] {
        guard !searchText.isEmpty else { return surahs }
        let q = searchText.lowercased()
        return surahs.filter {
            $0.nameSimple.lowercased().contains(q) ||
            $0.nameTranslation.lowercased().contains(q) ||
            $0.nameArabic.contains(searchText) ||
            "\($0.id)" == searchText
        }
    }
}

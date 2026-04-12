import SwiftUI

@MainActor
class ReciterListViewModel: ObservableObject {
    @Published var searchText = ""

    func filteredReciters(from reciters: [Reciter]) -> [Reciter] {
        guard !searchText.isEmpty else { return reciters }
        return reciters.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }
}

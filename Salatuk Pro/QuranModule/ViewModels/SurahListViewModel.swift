import Foundation
import Combine

class SurahListViewModel: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    private let service: QuranAPIProtocol

    init(service: QuranAPIProtocol = QuranAPIService.shared) {
        self.service = service
    }

    func loadSurahs() {
        isLoading = true
        service.fetchSurahs()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    print("Failed to fetch surahs", error)
                }
            }, receiveValue: { [weak self] surahs in
                self?.surahs = surahs
            })
            .store(in: &cancellables)
    }
}

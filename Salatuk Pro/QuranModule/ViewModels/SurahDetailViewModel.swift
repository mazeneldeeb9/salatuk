import Foundation
import Combine

class SurahDetailViewModel: ObservableObject {
    @Published var ayat: [Ayah] = []
    @Published var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    private let service: QuranAPIProtocol
    let surah: Surah

    init(surah: Surah, service: QuranAPIProtocol = QuranAPIService.shared) {
        self.surah = surah
        self.service = service
    }

    func loadAyat() {
        isLoading = true
        service.fetchAyat(forSurah: surah.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    print("Failed to fetch ayat", error)
                }
            }, receiveValue: { [weak self] ayat in
                self?.ayat = ayat
            })
            .store(in: &cancellables)
    }
}

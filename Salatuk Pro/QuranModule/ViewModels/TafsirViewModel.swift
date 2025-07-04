import Foundation
import Combine

class TafsirViewModel: ObservableObject {
    @Published var tafsir: Tafsir?
    @Published var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    private let service: QuranAPIProtocol
    let surah: Int
    let ayah: Int

    init(surah: Int, ayah: Int, service: QuranAPIProtocol = QuranAPIService.shared) {
        self.surah = surah
        self.ayah = ayah
        self.service = service
    }

    func loadTafsir() {
        isLoading = true
        service.fetchTafsir(surah: surah, ayah: ayah)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    print("Failed to fetch tafsir", error)
                }
            }, receiveValue: { [weak self] tafsir in
                self?.tafsir = tafsir
            })
            .store(in: &cancellables)
    }
}

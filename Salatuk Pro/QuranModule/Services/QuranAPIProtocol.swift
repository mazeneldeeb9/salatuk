import Foundation
import Combine

protocol QuranAPIProtocol {
    func fetchSurahs() -> AnyPublisher<[Surah], Error>
    func fetchAyat(forSurah number: Int) -> AnyPublisher<[Ayah], Error>
    func fetchTafsir(surah: Int, ayah: Int) -> AnyPublisher<Tafsir, Error>
}

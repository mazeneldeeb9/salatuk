import Foundation
import Combine

class QuranAPIService: QuranAPIProtocol {
    static let shared = QuranAPIService()
    private let session: URLSession
    private let baseURL = URL(string: "https://api.alquran.cloud/v1")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchSurahs() -> AnyPublisher<[Surah], Error> {
        let url = baseURL.appendingPathComponent("surah")
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SurahListResponse.self, decoder: JSONDecoder())
            .map { $0.data.map { Surah(id: $0.number,
                                       name: $0.name,
                                       englishName: $0.englishName,
                                       englishNameTranslation: $0.englishNameTranslation,
                                       numberOfAyahs: $0.numberOfAyahs) } }
            .eraseToAnyPublisher()
    }

    func fetchAyat(forSurah number: Int) -> AnyPublisher<[Ayah], Error> {
        let url = baseURL.appendingPathComponent("surah/\(number)/ar.uthmani")
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AyahListResponse.self, decoder: JSONDecoder())
            .map { $0.data.ayahs.map { Ayah(id: $0.number,
                                            text: $0.text,
                                            numberInSurah: $0.numberInSurah) } }
            .eraseToAnyPublisher()
    }

    func fetchTafsir(surah: Int, ayah: Int) -> AnyPublisher<Tafsir, Error> {
        // Placeholder endpoint; adjust with real tafsir API
        let url = URL(string: "https://api.quran.com/api/v4/tafsirs/by_ayah/\(ayah)?tafsir_id=169")!
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TafsirResponse.self, decoder: JSONDecoder())
            .tryMap { resp in
                guard let first = resp.tafsirs.first else {
                    throw URLError(.badServerResponse)
                }
                return Tafsir(id: first.id, text: first.text, source: first.resourceName)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models
private struct SurahListResponse: Codable {
    struct SurahData: Codable {
        let number: Int
        let name: String
        let englishName: String
        let englishNameTranslation: String?
        let numberOfAyahs: Int
    }
    let data: [SurahData]
}

private struct AyahListResponse: Codable {
    struct AyahData: Codable {
        let number: Int
        let text: String
        let numberInSurah: Int
    }
    struct AyahContainer: Codable {
        let ayahs: [AyahData]
    }
    let data: AyahContainer
}

private struct TafsirResponse: Codable {
    struct TafsirData: Codable {
        let id: Int
        let text: String
        let resourceName: String
    }
    let tafsirs: [TafsirData]
}

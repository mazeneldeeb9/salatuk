import Foundation

struct Surah: Identifiable, Codable {
    let id: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String?
    let numberOfAyahs: Int
}

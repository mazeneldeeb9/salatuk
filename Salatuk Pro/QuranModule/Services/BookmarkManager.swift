import Foundation

class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    @Published private(set) var bookmarks: Set<String> = [] // format: "surah:ayah"
    private let defaultsKey = "quranBookmarks"

    private init() {
        if let saved = UserDefaults.standard.array(forKey: defaultsKey) as? [String] {
            bookmarks = Set(saved)
        }
    }

    func toggleBookmark(surah: Int, ayah: Int) {
        let key = "\(surah):\(ayah)"
        if bookmarks.contains(key) {
            bookmarks.remove(key)
        } else {
            bookmarks.insert(key)
        }
        UserDefaults.standard.set(Array(bookmarks), forKey: defaultsKey)
        // TODO: Sync with iCloud
    }

    func isBookmarked(surah: Int, ayah: Int) -> Bool {
        bookmarks.contains("\(surah):\(ayah)")
    }
}

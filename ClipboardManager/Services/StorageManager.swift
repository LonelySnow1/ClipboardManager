import Foundation

class StorageManager {
    private let storageKey = "clipboard_history"
    private let maxItems: Int

    init(maxItems: Int = 50) {
        self.maxItems = maxItems
    }

    func load() -> [ClipboardItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ items: [ClipboardItem]) {
        let trimmed = Array(items.prefix(maxItems))
        do {
            let data = try JSONEncoder().encode(trimmed)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {}
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

import SwiftUI
import AppKit

class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let monitor = ClipboardMonitor()
    private let storage = StorageManager()
    private var isInternalCopy = false

    init() {
        items = storage.load()

        monitor.onNewContent = { [weak self] content in
            guard let self = self, !self.isInternalCopy else { return }
            self.addItem(content: content)
        }
        monitor.start()
    }

    func addItem(content: String) {
        if let existingIndex = items.firstIndex(where: { $0.content == content }) {
            items.remove(at: existingIndex)
        }

        let item = ClipboardItem(content: content)
        items.insert(item, at: 0)

        if items.count > 50 {
            items = Array(items.prefix(50))
        }

        storage.save(items)
    }

    func selectItem(_ item: ClipboardItem) {
        isInternalCopy = true
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isInternalCopy = false
        }

        simulatePaste()
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        storage.save(items)
    }

    func clearAll() {
        items.removeAll()
        storage.clear()
    }

    private func simulatePaste() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            keyDown?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)

            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyUp?.flags = .maskCommand
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}

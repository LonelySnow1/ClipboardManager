import SwiftUI
import AppKit

class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = ""

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter {
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var targetPID: pid_t?

    private let monitor = ClipboardMonitor()
    private let storage = StorageManager()
    private var isInternalCopy = false
    private(set) var isPanelOpen = false

    init() {
        items = storage.load()

        monitor.onNewContent = { [weak self] content in
            guard let self = self, !self.isInternalCopy, !self.isPanelOpen else { return }
            self.addItem(content: content)
        }
        monitor.start()
    }

    func panelDidOpen() {
        isPanelOpen = true
        selectedIndex = 0
        searchText = ""
    }

    func panelDidClose() {
        isPanelOpen = false
        selectedIndex = 0
        searchText = ""
    }

    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func moveSelectionDown() {
        if selectedIndex < filteredItems.count - 1 {
            selectedIndex += 1
        }
    }

    func confirmSelection() {
        let items = filteredItems
        guard !items.isEmpty, selectedIndex >= 0, selectedIndex < items.count else { return }
        selectItem(items[selectedIndex])
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
        let pid = targetPID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            keyDown?.flags = .maskCommand

            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyUp?.flags = .maskCommand

            if let pid = pid {
                keyDown?.postToPid(pid)
                keyUp?.postToPid(pid)
            } else {
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
            }
        }
    }
}

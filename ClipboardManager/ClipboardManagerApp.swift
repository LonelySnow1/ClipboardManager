import SwiftUI
import AppKit

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var panel: NSPanel?
    var viewModel = ClipboardViewModel()
    private let hotKeyManager = HotKeyManager()
    private var cachedFocusedElementPosition: NSPoint?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(togglePanel)
            button.target = self
        }

        setupPanel()

        hotKeyManager.onHotKey = { [weak self] in
            guard let self = self else { return }
            self.cachedFocusedElementPosition = self.getFocusedElementPosition()
            DispatchQueue.main.async {
                self.showPanel()
            }
        }
        hotKeyManager.register()
    }

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.contentViewController = NSHostingController(rootView: ClipboardPanelView(viewModel: viewModel))
        self.panel = panel
    }

    @objc func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            cachedFocusedElementPosition = getFocusedElementPosition()
            showPanel()
        }
    }

    func showPanel() {
        guard let panel = panel else { return }
        let panelSize = panel.frame.size
        var origin: NSPoint

        if let pos = cachedFocusedElementPosition {
            origin = NSPoint(
                x: pos.x,
                y: pos.y - panelSize.height
            )
        } else {
            let mouseLocation = NSEvent.mouseLocation
            origin = NSPoint(
                x: mouseLocation.x - panelSize.width / 2,
                y: mouseLocation.y - panelSize.height
            )
        }

        if let screen = NSScreen.screens.first(where: { $0.frame.contains(origin) }) ?? NSScreen.main {
            let visibleFrame = screen.visibleFrame
            if origin.x < visibleFrame.minX { origin.x = visibleFrame.minX }
            if origin.x + panelSize.width > visibleFrame.maxX { origin.x = visibleFrame.maxX - panelSize.width }
            if origin.y < visibleFrame.minY { origin.y = visibleFrame.minY }
            if origin.y + panelSize.height > visibleFrame.maxY { origin.y = visibleFrame.maxY - panelSize.height }
        }

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    private func getFocusedElementPosition() -> NSPoint? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = focusedApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedElementRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
              let focusedElement = focusedElementRef as! AXUIElement? else {
            return nil
        }

        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focusedElement, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(focusedElement, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionRef as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size) else {
            return nil
        }

        guard let screen = NSScreen.main else { return nil }
        let screenHeight = screen.frame.height
        let flippedY = screenHeight - position.y - size.height

        return NSPoint(x: position.x, y: flippedY)
    }
}

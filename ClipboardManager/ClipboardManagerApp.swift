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
    private var localKeyMonitor: Any?
    private var globalClickMonitor: Any?

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
            DispatchQueue.main.async {
                self.togglePanel()
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
            dismissPanel()
        } else {
            cachedFocusedElementPosition = getFocusedElementPosition()
            showPanel()
        }
    }

    func dismissPanel() {
        panel?.orderOut(nil)
        removeEventMonitors()
        viewModel.panelDidClose()
    }

    func showPanel() {
        guard let panel = panel else { return }
        viewModel.panelDidOpen()
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
        addEventMonitors()
    }

    private func addEventMonitors() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismissPanel()
                return nil
            }
            return event
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let panel = self.panel else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLocation) {
                self.dismissPanel()
            }
        }
    }

    private func removeEventMonitors() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
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

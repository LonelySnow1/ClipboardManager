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
    private let panelKeyHandler = PanelKeyHandler()
    private var cachedFocusedElementRect: NSRect?
    private var cachedFrontmostPID: pid_t?
    private var cachedFrontmostWindowFrame: NSRect?
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
        setupPanelKeyHandler()

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
            cachedFrontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
            cachedFocusedElementRect = getFocusedElementRect()
            cachedFrontmostWindowFrame = getFrontmostWindowFrame()
            viewModel.targetPID = cachedFrontmostPID
            showPanel()
        }
    }

    func dismissPanel() {
        panel?.orderOut(nil)
        panelKeyHandler.disable()
        removeEventMonitors()
        viewModel.panelDidClose()
    }

    func showPanel() {
        guard let panel = panel else { return }
        viewModel.panelDidOpen()
        let panelSize = panel.frame.size
        let spacing: CGFloat = 4

        let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        var origin: NSPoint

        if let elementRect = cachedFocusedElementRect {
            let spaceBelow = elementRect.minY - visibleFrame.minY
            let spaceAbove = visibleFrame.maxY - elementRect.maxY

            if spaceBelow >= panelSize.height + spacing {
                origin = NSPoint(
                    x: elementRect.minX,
                    y: elementRect.minY - panelSize.height - spacing
                )
            } else if spaceAbove >= panelSize.height + spacing {
                origin = NSPoint(
                    x: elementRect.minX,
                    y: elementRect.maxY + spacing
                )
            } else {
                origin = NSPoint(
                    x: elementRect.minX,
                    y: elementRect.minY - panelSize.height - spacing
                )
            }
        } else if let windowFrame = cachedFrontmostWindowFrame {
            origin = NSPoint(
                x: windowFrame.midX - panelSize.width / 2,
                y: windowFrame.midY - panelSize.height / 2
            )
        } else {
            origin = NSPoint(
                x: visibleFrame.midX - panelSize.width / 2,
                y: visibleFrame.midY - panelSize.height / 2
            )
        }

        origin.x = max(visibleFrame.minX, min(origin.x, visibleFrame.maxX - panelSize.width))
        origin.y = max(visibleFrame.minY, min(origin.y, visibleFrame.maxY - panelSize.height))

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        panelKeyHandler.enable()
        addEventMonitors()
    }

    private func setupPanelKeyHandler() {
        panelKeyHandler.onMoveUp = { [weak self] in self?.viewModel.moveSelectionUp() }
        panelKeyHandler.onMoveDown = { [weak self] in self?.viewModel.moveSelectionDown() }
        panelKeyHandler.onConfirm = { [weak self] in self?.viewModel.confirmSelection() }
        panelKeyHandler.onDismiss = { [weak self] in self?.dismissPanel() }
    }

    private func addEventMonitors() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let panel = self.panel else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLocation) {
                self.dismissPanel()
            }
        }
    }

    private func removeEventMonitors() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }

    private func getFocusedElementRect() -> NSRect? {
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

        return NSRect(x: position.x, y: flippedY, width: size.width, height: size.height)
    }

    private func getFrontmostWindowFrame() -> NSRect? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = focusedApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement],
              let frontWindow = windows.first else {
            return nil
        }

        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(frontWindow, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(frontWindow, kAXSizeAttribute as CFString, &sizeRef) == .success else {
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

        return NSRect(x: position.x, y: flippedY, width: size.width, height: size.height)
    }
}

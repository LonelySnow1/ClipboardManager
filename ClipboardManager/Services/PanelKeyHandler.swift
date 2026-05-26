import AppKit

class PanelKeyHandler {
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onConfirm: (() -> Void)?
    var onDismiss: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func enable() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let handler = Unmanaged<PanelKeyHandler>.fromOpaque(refcon).takeUnretainedValue()
                return handler.handle(event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func disable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
    }

    private func handle(event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let noModifiers = !flags.contains(.maskCommand) &&
                          !flags.contains(.maskShift) &&
                          !flags.contains(.maskControl) &&
                          !flags.contains(.maskAlternate)

        switch keyCode {
        case 126 where noModifiers:
            DispatchQueue.main.async { self.onMoveUp?() }
            return nil
        case 125 where noModifiers:
            DispatchQueue.main.async { self.onMoveDown?() }
            return nil
        case 36 where noModifiers:
            DispatchQueue.main.async { self.onConfirm?() }
            return nil
        case 53 where noModifiers:
            DispatchQueue.main.async { self.onDismiss?() }
            return nil
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    deinit {
        disable()
    }
}

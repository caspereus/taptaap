import AppKit
import Foundation

/// Input delivered by a keyboard event source for overlay display.
struct KeyboardOverlayInput: Sendable {
    let keyCode: UInt16
    let modifierFlags: NSEvent.ModifierFlags
}

/// Abstraction for keyboard event sources.
///
/// MVP uses `NSEvent` global/local monitors. Overlay logic stays behind this
/// protocol so the source can later be swapped for `CGEventTap` without
/// changing `KeyboardOverlayManager`.
protocol KeyboardEventMonitoring: AnyObject {
    var isRunning: Bool { get }
    func start(handler: @escaping @Sendable (KeyboardOverlayInput) -> Void)
    func stop()
}

/// Passive keyboard monitor using `NSEvent.addGlobalMonitorForEvents` (MVP).
///
/// Privacy: Reads key codes and modifier flags only for on-screen display.
/// Nothing is stored, logged, or transmitted.
final class NSEventKeyboardMonitor: KeyboardEventMonitoring {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private(set) var isRunning = false

    func start(handler: @escaping @Sendable (KeyboardOverlayInput) -> Void) {
        guard !isRunning else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard event.type == .keyDown else { return }
            handler(
                KeyboardOverlayInput(
                    keyCode: event.keyCode,
                    modifierFlags: event.modifierFlags
                )
            )
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .keyDown {
                handler(
                    KeyboardOverlayInput(
                        keyCode: event.keyCode,
                        modifierFlags: event.modifierFlags
                    )
                )
            }
            return event
        }

        isRunning = globalMonitor != nil || localMonitor != nil
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        isRunning = false
    }
}

import Foundation

/// Coordinates keyboard monitoring, filtering, and overlay presentation.
///
/// Privacy: Only the latest key/shortcut is shown locally. Nothing is persisted,
/// logged, or sent over the network.
@MainActor
final class KeyboardOverlayManager {
    static let shared = KeyboardOverlayManager()

    private let windowController = OverlayWindowController()
    private let eventMonitor: KeyboardEventMonitoring
    private var hideTimer: Timer?
    private var isActive = false

    private var showMode: OverlayShowMode = .shortcutsOnly
    private var privacyMode = false
    private var position: OverlayPosition = .bottomCenter
    private var hideDelay: TimeInterval = 1.0
    private var theme: OverlayTheme = .graphite

    init(eventMonitor: KeyboardEventMonitoring = NSEventKeyboardMonitor()) {
        self.eventMonitor = eventMonitor
    }

    func setActive(
        _ active: Bool,
        showMode: OverlayShowMode,
        privacyMode: Bool,
        position: OverlayPosition,
        hideDelay: TimeInterval,
        theme: OverlayTheme
    ) {
        self.showMode = showMode
        self.privacyMode = privacyMode
        self.position = position
        self.hideDelay = hideDelay
        self.theme = theme
        isActive = active

        if active {
            startMonitoring()
        } else {
            stopMonitoring()
            windowController.hide()
        }
    }

    func updateConfiguration(
        showMode: OverlayShowMode,
        privacyMode: Bool,
        position: OverlayPosition,
        hideDelay: TimeInterval,
        theme: OverlayTheme
    ) {
        self.showMode = showMode
        self.privacyMode = privacyMode
        self.position = position
        self.hideDelay = hideDelay
        self.theme = theme
        windowController.updatePosition(position)
    }

    private func startMonitoring() {
        guard !eventMonitor.isRunning else { return }

        eventMonitor.start { [weak self] input in
            Task { @MainActor in
                self?.handleInput(input)
            }
        }
    }

    private func stopMonitoring() {
        cancelHideTimer()
        eventMonitor.stop()
    }

    private func handleInput(_ input: KeyboardOverlayInput) {
        guard isActive else { return }

        let labels = KeyFormatter.keycapLabels(
            keyCode: input.keyCode,
            modifierFlags: input.modifierFlags
        )
        guard !labels.isEmpty else { return }
        guard shouldDisplay(input: input, labels: labels) else { return }

        windowController.show(keycaps: labels, position: position, theme: theme)
        scheduleHide()
    }

    private func shouldDisplay(input: KeyboardOverlayInput, labels: [String]) -> Bool {
        let hasActionModifiers = KeyFormatter.hasActionModifiers(input.modifierFlags)
        let isNormalKey = KeyFormatter.isNormalTypingKey(keyCode: input.keyCode)
        let isSpecialKey = KeyFormatter.isSpecialKey(keyCode: input.keyCode)

        switch showMode {
        case .shortcutsOnly:
            return hasActionModifiers
        case .allKeystrokes:
            if privacyMode, isNormalKey, !hasActionModifiers {
                return false
            }
            if privacyMode, !hasActionModifiers, !isSpecialKey, !isNormalKey {
                return false
            }
            return true
        }
    }

    private func scheduleHide() {
        cancelHideTimer()
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.windowController.hide()
            }
        }
    }

    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
}

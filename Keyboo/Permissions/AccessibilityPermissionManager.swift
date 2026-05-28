import AppKit
import ApplicationServices
import Combine
import Foundation

/// Manages Accessibility permission required for global keyboard overlay monitoring.
///
/// Privacy: Used only to attach passive event monitors. Keyboo never persists,
/// logs, or transmits key events captured for the overlay.
@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    static let shared = AccessibilityPermissionManager()

    @Published private(set) var hasAccessibilityAccess = false

    private var activationObserver: NSObjectProtocol?
    private var pollingTimer: Timer?

    private init() {
        refreshAccessStatus()
        startObservingForegroundChanges()
    }

    deinit {
        pollingTimer?.invalidate()
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
    }

    func refreshAccessStatus() {
        hasAccessibilityAccess = AXIsProcessTrustedWithOptions(nil)

        if hasAccessibilityAccess {
            stopPolling()
        } else {
            startPollingIfNeeded()
        }
    }

    @discardableResult
    func requestAccess() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        refreshAccessStatus()
        return granted
    }

    func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func startObservingForegroundChanges() {
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAccessStatus()
            }
        }
    }

    private func startPollingIfNeeded() {
        guard !hasAccessibilityAccess, pollingTimer == nil else { return }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAccessStatus()
            }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

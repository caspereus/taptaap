import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation

/// Manages Input Monitoring permission required for global keyboard listening.
///
/// Privacy: Keyboo only reads virtual key codes via CGEventTap to trigger sound playback.
/// It never captures, stores, or transmits typed characters or text content.
/// No network calls. No analytics. No logging of key presses.
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published private(set) var hasInputMonitoringAccess = false

    /// True when Accessibility is granted but Input Monitoring is not — a common mix-up.
    var hasAccessibilityOnly: Bool {
        !hasInputMonitoringAccess && AXIsProcessTrusted()
    }

    private var activationObserver: NSObjectProtocol?
    private var workspaceObserver: NSObjectProtocol?
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
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
    }

    /// Menu bar apps (`LSUIElement`) often never become "active", so permission
    /// changes made in System Settings are easy to miss without polling.
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

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard self?.hasInputMonitoringAccess == false else { return }
                self?.refreshAccessStatus()
            }
        }
    }

    private func startPollingIfNeeded() {
        guard !hasInputMonitoringAccess, pollingTimer == nil else { return }

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

    func refreshAccessStatus() {
        hasInputMonitoringAccess = CGPreflightListenEventAccess()

        if hasInputMonitoringAccess {
            stopPolling()
        } else {
            startPollingIfNeeded()
        }
    }

    @discardableResult
    func requestAccess() -> Bool {
        let granted = CGRequestListenEventAccess()
        refreshAccessStatus()
        return granted
    }

    func openInputMonitoringSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

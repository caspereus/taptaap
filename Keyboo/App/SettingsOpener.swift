import AppKit
import SwiftUI

extension Notification.Name {
    static let openSettingsRequest = Notification.Name("meecanico.openSettingsRequest")
    static let settingsWindowClosed = Notification.Name("meecanico.settingsWindowClosed")
}

private enum SettingsWindowIdentifiers {
    static let settings = "com.apple.SwiftUI.Settings"
    static let host = "settings-host"
}

enum SettingsWindowOpener {
    static var isHostWindowLoaded: Bool {
        NSApp.windows.contains { $0.identifier?.rawValue == SettingsWindowIdentifiers.host }
    }

    static func ensureHostWindowVisible() {
        guard let hostWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == SettingsWindowIdentifiers.host }) else {
            return
        }
        hostWindow.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        hostWindow.orderBack(nil)
    }

    static func requestOpenSettings() {
        NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
    }

    static func notifySettingsClosed() {
        NotificationCenter.default.post(name: .settingsWindowClosed, object: nil)
    }

    static func findSettingsWindow() -> NSWindow? {
        NSApp.windows.first { window in
            if window.identifier?.rawValue == SettingsWindowIdentifiers.settings {
                return true
            }

            if window.isVisible,
               window.styleMask.contains(.titled),
               window.title.localizedCaseInsensitiveContains("settings")
                || window.title.localizedCaseInsensitiveContains("preferences") {
                return true
            }

            if let contentVC = window.contentViewController,
               String(describing: type(of: contentVC)).contains("Settings") {
                return true
            }

            return false
        }
    }
}

/// Minimal hidden window that provides a SwiftUI context for `@Environment(\.openSettings)`.
/// Required for MenuBarExtra apps where `showSettingsWindow:` does not reliably work.
struct SettingsHostWindowView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .background(SettingsHostWindowConfigurator())
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsRequest)) { _ in
                Task { @MainActor in
                    NSApp.setActivationPolicy(.regular)
                    try? await Task.sleep(for: .milliseconds(100))

                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()

                    try? await Task.sleep(for: .milliseconds(200))
                    if let settingsWindow = SettingsWindowOpener.findSettingsWindow() {
                        settingsWindow.makeKeyAndOrderFront(nil)
                        settingsWindow.orderFrontRegardless()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .settingsWindowClosed)) { _ in
                Task { @MainActor in
                    NSApp.setActivationPolicy(.accessory)
                }
            }
    }
}

private struct SettingsHostWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.identifier = NSUserInterfaceItemIdentifier(SettingsWindowIdentifiers.host)
            window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
            window.isReleasedWhenClosed = false
            window.isExcludedFromWindowsMenu = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

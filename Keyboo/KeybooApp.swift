import SwiftUI

@main
struct KeybooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared

    private var shouldShowPermissionOnboarding: Bool {
        !settings.hasCompletedPermissionOnboarding
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .onAppear {
                    syncServices()
                }
                .onChange(of: settings.isEnabled) { _, _ in
                    syncKeyboardMonitor()
                    syncVisualizer()
                }
                .onChange(of: settings.selectedProfile) { _, newValue in
                    SoundEngine.shared.reloadProfile(newValue)
                    TypingVisualizer.shared.updateAccentColor(newValue.swatchColor)
                }
                .onChange(of: settings.enableVisualizer) { _, _ in
                    syncVisualizer()
                }
                .onChange(of: settings.menuBarPosition) { _, newValue in
                    TypingVisualizer.shared.updatePosition(newValue)
                }
                .onChange(of: permissions.hasInputMonitoringAccess) { _, _ in
                    syncServices()
                }
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)

        Window("Welcome to Keyboo", id: PermissionOnboardingWindow.id) {
            PermissionOnboardingView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(shouldShowPermissionOnboarding ? .presented : .suppressed)
        .defaultPosition(.center)

        Settings {
            SettingsView()
        }
    }

    private func syncServices() {
        permissions.refreshAccessStatus()
        SoundEngine.shared.reloadProfile(settings.selectedProfile)
        syncKeyboardMonitor()
        syncVisualizer()
    }

    private func syncVisualizer() {
        let active = settings.isEnabled
            && settings.enableVisualizer
            && permissions.hasInputMonitoringAccess
        TypingVisualizer.shared.setActive(
            active,
            position: settings.menuBarPosition,
            accentColor: settings.selectedProfile.swatchColor
        )
    }

    private func syncKeyboardMonitor() {
        let active = settings.isEnabled && permissions.hasInputMonitoringAccess
        KeyboardEventMonitor.shared.setMonitoringActive(active)

        if active {
            KeyboardEventMonitor.shared.start()
        } else {
            KeyboardEventMonitor.shared.stop()
        }
    }
}

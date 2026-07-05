import SwiftUI

@main
struct KeybooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var settings = AppSettings.shared

    private var shouldShowPermissionOnboarding: Bool {
        !settings.hasCompletedPermissionOnboarding
    }

    var body: some Scene {
        // Must come before Settings so `@Environment(\.openSettings)` resolves in the host view.
        Window("Settings Host", id: "settings-host") {
            SettingsHostWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
        .defaultPosition(.init(x: -10_000, y: -10_000))
        .defaultLaunchBehavior(.presented)

        MenuBarExtra {
            MenuBarView()
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)

        Window("Welcome to Meecanico", id: PermissionOnboardingWindow.id) {
            PermissionOnboardingView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(shouldShowPermissionOnboarding ? .presented : .suppressed)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .onDisappear {
                    SettingsWindowOpener.notifySettingsClosed()
                }
        }
    }
}

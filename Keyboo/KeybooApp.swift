import SwiftUI

@main
struct KeybooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var settings = AppSettings.shared

    private var shouldShowPermissionOnboarding: Bool {
        !settings.hasCompletedPermissionOnboarding
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)

        Window("Welcome to Taptaap", id: PermissionOnboardingWindow.id) {
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
}

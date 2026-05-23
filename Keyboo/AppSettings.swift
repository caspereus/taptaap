import Combine
import Foundation

enum MenuBarPosition: String, CaseIterable, Identifiable {
    case left
    case center
    case right

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .left: "Left"
        case .center: "Center"
        case .right: "Right"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let isEnabled = "keyboo.isEnabled"
        static let selectedProfile = "keyboo.selectedProfile"
        static let launchAtLogin = "keyboo.launchAtLogin"
        static let enableVisualizer = "keyboo.enableVisualizer"
        static let menuBarPosition = "keyboo.menuBarPosition"
        static let hasCompletedPermissionOnboarding = "keyboo.hasCompletedPermissionOnboarding"
    }

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var selectedProfile: SoundProfileID {
        didSet { UserDefaults.standard.set(selectedProfile.rawValue, forKey: Keys.selectedProfile) }
    }

    /// Placeholder for a future Launch-at-Login implementation.
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var enableVisualizer: Bool {
        didSet { UserDefaults.standard.set(enableVisualizer, forKey: Keys.enableVisualizer) }
    }

    @Published var menuBarPosition: MenuBarPosition {
        didSet { UserDefaults.standard.set(menuBarPosition.rawValue, forKey: Keys.menuBarPosition) }
    }

    @Published var hasCompletedPermissionOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedPermissionOnboarding, forKey: Keys.hasCompletedPermissionOnboarding) }
    }

    private init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        selectedProfile = SoundProfileID(
            rawValue: defaults.string(forKey: Keys.selectedProfile) ?? SoundProfileID.default.rawValue
        ) ?? .default
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        enableVisualizer = defaults.object(forKey: Keys.enableVisualizer) as? Bool ?? false
        menuBarPosition = MenuBarPosition(
            rawValue: defaults.string(forKey: Keys.menuBarPosition) ?? MenuBarPosition.center.rawValue
        ) ?? .center
        hasCompletedPermissionOnboarding = defaults.bool(forKey: Keys.hasCompletedPermissionOnboarding)
    }
}

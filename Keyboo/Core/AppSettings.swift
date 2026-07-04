import AppKit
import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let isEnabled = "keyboo.isEnabled"
        static let selectedProfile = "keyboo.selectedProfile"
        static let launchAtLogin = "keyboo.launchAtLogin"
        static let enableVisualizer = "keyboo.enableVisualizer"
        static let visualizerPosition = "keyboo.visualizerPosition"
        static let legacyMenuBarPosition = "keyboo.menuBarPosition"
        static let visualizerTheme = "keyboo.visualizerTheme"
        static let hasCompletedPermissionOnboarding = "keyboo.hasCompletedPermissionOnboarding"
        static let outputVolume = "keyboo.outputVolume"
    }

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var selectedProfile: SoundProfileID {
        didSet { UserDefaults.standard.set(selectedProfile.rawValue, forKey: Keys.selectedProfile) }
    }

    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var outputVolume: Double {
        didSet {
            let clamped = min(max(outputVolume, 0), 1)
            if clamped != outputVolume {
                outputVolume = clamped
                return
            }
            UserDefaults.standard.set(outputVolume, forKey: Keys.outputVolume)
        }
    }

    @Published var enableVisualizer: Bool {
        didSet { UserDefaults.standard.set(enableVisualizer, forKey: Keys.enableVisualizer) }
    }

    @Published var visualizerPosition: VisualizerPosition {
        didSet { UserDefaults.standard.set(visualizerPosition.rawValue, forKey: Keys.visualizerPosition) }
    }

    @Published var visualizerTheme: VisualizerTheme {
        didSet { UserDefaults.standard.set(visualizerTheme.rawValue, forKey: Keys.visualizerTheme) }
    }

    @Published var hasCompletedPermissionOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedPermissionOnboarding, forKey: Keys.hasCompletedPermissionOnboarding) }
    }

    @Published var requestedSettingsTab: SettingsTab?

    func cycleToNextProfile() {
        let profiles = SoundProfileID.allCases
        guard let index = profiles.firstIndex(of: selectedProfile) else {
            selectedProfile = profiles.first ?? .default
            return
        }
        let nextIndex = (index + 1) % profiles.count
        selectedProfile = profiles[nextIndex]
    }

    func openSettings(tab: SettingsTab? = nil) {
        requestedSettingsTab = tab
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        selectedProfile = SoundProfileID(
            rawValue: defaults.string(forKey: Keys.selectedProfile) ?? SoundProfileID.default.rawValue
        ) ?? .default
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        let storedVolume = defaults.object(forKey: Keys.outputVolume) as? Double ?? 1.0
        outputVolume = min(max(storedVolume, 0), 1)
        enableVisualizer = defaults.object(forKey: Keys.enableVisualizer) as? Bool ?? false

        if let storedPosition = defaults.string(forKey: Keys.visualizerPosition) {
            visualizerPosition = VisualizerPosition(rawValue: storedPosition) ?? .bottomCenter
        } else if let legacyPosition = defaults.string(forKey: Keys.legacyMenuBarPosition) {
            visualizerPosition = VisualizerPosition.migrated(from: legacyPosition)
        } else {
            visualizerPosition = .bottomCenter
        }

        visualizerTheme = VisualizerTheme(
            rawValue: defaults.string(forKey: Keys.visualizerTheme) ?? VisualizerTheme.arctic.rawValue
        ) ?? .arctic

        hasCompletedPermissionOnboarding = defaults.bool(forKey: Keys.hasCompletedPermissionOnboarding)
    }
}

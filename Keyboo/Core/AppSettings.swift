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
        static let enableSound = "keyboo.enableSound"
        static let enableVisualizer = "keyboo.enableVisualizer"
        static let visualizerRequiresExplicitOptIn = "keyboo.visualizerRequiresExplicitOptIn"
        static let visualizerPosition = "keyboo.visualizerPosition"
        static let legacyMenuBarPosition = "keyboo.menuBarPosition"
        static let visualizerTheme = "keyboo.visualizerTheme"
        static let hasCompletedPermissionOnboarding = "keyboo.hasCompletedPermissionOnboarding"
        static let outputVolume = "keyboo.outputVolume"
        static let enableSpatialAudio = "keyboo.enableSpatialAudio"
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

    @Published var enableSpatialAudio: Bool {
        didSet { UserDefaults.standard.set(enableSpatialAudio, forKey: Keys.enableSpatialAudio) }
    }

    @Published var enableSound: Bool {
        didSet { UserDefaults.standard.set(enableSound, forKey: Keys.enableSound) }
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
        // Defer until the menu bar menu closes; opening a window synchronously from
        // MenuBarExtra menu actions is ignored by AppKit.
        Task { @MainActor in
            requestedSettingsTab = tab
            try? await Task.sleep(for: .milliseconds(50))
            SettingsWindowOpener.ensureHostWindowVisible()
            SettingsWindowOpener.requestOpenSettings()
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.enableSound: true,
            Keys.enableVisualizer: false,
            Keys.launchAtLogin: false,
            Keys.outputVolume: 1.0,
            Keys.enableSpatialAudio: true,
            Keys.hasCompletedPermissionOnboarding: false,
        ])

        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        selectedProfile = SoundProfileID(
            rawValue: defaults.string(forKey: Keys.selectedProfile) ?? SoundProfileID.default.rawValue
        ) ?? .default
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        let storedVolume = defaults.object(forKey: Keys.outputVolume) as? Double ?? 1.0
        outputVolume = min(max(storedVolume, 0), 1)
        enableSpatialAudio = defaults.object(forKey: Keys.enableSpatialAudio) as? Bool ?? true
        enableSound = defaults.object(forKey: Keys.enableSound) as? Bool ?? true

        // The old menu-bar Toggle could write `enableVisualizer = true` without user intent.
        // Reset once so the overlay stays off until the user explicitly enables it.
        if !defaults.bool(forKey: Keys.visualizerRequiresExplicitOptIn) {
            defaults.set(false, forKey: Keys.enableVisualizer)
            defaults.set(true, forKey: Keys.visualizerRequiresExplicitOptIn)
        }
        enableVisualizer = defaults.bool(forKey: Keys.enableVisualizer)

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

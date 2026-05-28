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
        static let enableKeyboardOverlay = "keyboo.enableKeyboardOverlay"
        static let overlayShowMode = "keyboo.overlayShowMode"
        static let overlayPosition = "keyboo.overlayPosition"
        static let overlayHideDelay = "keyboo.overlayHideDelay"
        static let overlayPrivacyMode = "keyboo.overlayPrivacyMode"
        static let overlayTheme = "keyboo.overlayTheme"
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

    @Published var enableKeyboardOverlay: Bool {
        didSet { UserDefaults.standard.set(enableKeyboardOverlay, forKey: Keys.enableKeyboardOverlay) }
    }

    @Published var overlayShowMode: OverlayShowMode {
        didSet { UserDefaults.standard.set(overlayShowMode.rawValue, forKey: Keys.overlayShowMode) }
    }

    @Published var overlayPosition: OverlayPosition {
        didSet { UserDefaults.standard.set(overlayPosition.rawValue, forKey: Keys.overlayPosition) }
    }

    @Published var overlayHideDelay: Double {
        didSet {
            let clamped = min(max(overlayHideDelay, 0.5), 3.0)
            if clamped != overlayHideDelay {
                overlayHideDelay = clamped
                return
            }
            UserDefaults.standard.set(overlayHideDelay, forKey: Keys.overlayHideDelay)
        }
    }

    @Published var overlayPrivacyMode: Bool {
        didSet { UserDefaults.standard.set(overlayPrivacyMode, forKey: Keys.overlayPrivacyMode) }
    }

    @Published var overlayTheme: OverlayTheme {
        didSet { UserDefaults.standard.set(overlayTheme.rawValue, forKey: Keys.overlayTheme) }
    }

    @Published var requestedSettingsTab: SettingsTab?

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

        enableKeyboardOverlay = defaults.object(forKey: Keys.enableKeyboardOverlay) as? Bool ?? false
        overlayShowMode = OverlayShowMode(
            rawValue: defaults.string(forKey: Keys.overlayShowMode) ?? OverlayShowMode.shortcutsOnly.rawValue
        ) ?? .shortcutsOnly
        overlayPosition = OverlayPosition(
            rawValue: defaults.string(forKey: Keys.overlayPosition) ?? OverlayPosition.bottomCenter.rawValue
        ) ?? .bottomCenter
        overlayHideDelay = defaults.object(forKey: Keys.overlayHideDelay) as? Double ?? 1.0
        overlayPrivacyMode = defaults.object(forKey: Keys.overlayPrivacyMode) as? Bool ?? false
        overlayTheme = OverlayTheme(
            rawValue: defaults.string(forKey: Keys.overlayTheme) ?? OverlayTheme.graphite.rawValue
        ) ?? .graphite
    }
}

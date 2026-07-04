import Combine
import Foundation

@MainActor
final class SettingsServiceCoordinator {
    static let shared = SettingsServiceCoordinator()

    private let settings = AppSettings.shared
    private let permissions = PermissionManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        bindSettings()
    }

    func start() {
        permissions.refreshAccessStatus()
        syncAll()
    }

    private func bindSettings() {
        settings.$isEnabled
            .dropFirst()
            .sink { [weak self] _ in
                self?.syncKeyboardMonitor()
                self?.syncVisualizer()
            }
            .store(in: &cancellables)

        settings.$selectedProfile
            .dropFirst()
            .sink { profile in
                SoundEngine.shared.reloadProfile(profile)
                SoundEngine.shared.playPreview()
            }
            .store(in: &cancellables)

        settings.$outputVolume
            .dropFirst()
            .sink { volume in
                SoundEngine.shared.setOutputVolume(Float(volume))
            }
            .store(in: &cancellables)

        settings.$enableSpatialAudio
            .dropFirst()
            .sink { enabled in
                SoundEngine.shared.setSpatialAudioEnabled(enabled)
                SoundEngine.shared.playPreview()
            }
            .store(in: &cancellables)

        settings.$enableVisualizer
            .dropFirst()
            .sink { [weak self] _ in
                self?.syncVisualizer()
            }
            .store(in: &cancellables)

        settings.$visualizerPosition
            .dropFirst()
            .sink { position in
                TypingVisualizer.shared.updatePosition(position)
            }
            .store(in: &cancellables)

        settings.$visualizerTheme
            .dropFirst()
            .sink { theme in
                TypingVisualizer.shared.updateTheme(theme)
            }
            .store(in: &cancellables)

        permissions.$hasInputMonitoringAccess
            .dropFirst()
            .sink { [weak self] _ in
                self?.syncAll()
            }
            .store(in: &cancellables)
    }

    private func syncAll() {
        SoundEngine.shared.setOutputVolume(Float(settings.outputVolume))
        SoundEngine.shared.setSpatialAudioEnabled(settings.enableSpatialAudio)
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
            position: settings.visualizerPosition,
            theme: settings.visualizerTheme
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

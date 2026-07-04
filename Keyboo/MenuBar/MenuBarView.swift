import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if !settings.isEnabled {
                Button {
                    settings.isEnabled = true
                } label: {
                    Label("Enable Taptaap", systemImage: "keyboard")
                }
                .disabled(!permissions.hasInputMonitoringAccess)
            }

            Menu {
                switchPicker
            } label: {
                Label {
                    Text(settings.selectedProfile.switchName)
                } icon: {
                    Image(nsImage: SwitchSwatchImage.image(for: settings.selectedProfile))
                }
            }

            Menu {
                Toggle(isOn: $settings.enableVisualizer) {
                    Label("Show While Typing", systemImage: "eye")
                }
                .disabled(!permissions.hasInputMonitoringAccess)

                Divider()

                Picker("Position", selection: $settings.visualizerPosition) {
                    ForEach(VisualizerPosition.allCases) { position in
                        Text(position.displayName).tag(position)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
                .disabled(!permissions.hasInputMonitoringAccess || !settings.enableVisualizer)

                Picker("Theme", selection: $settings.visualizerTheme) {
                    ForEach(VisualizerTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
                .disabled(!permissions.hasInputMonitoringAccess || !settings.enableVisualizer)
            } label: {
                Label("Visualizer", systemImage: "gauge.with.dots.needle.67percent")
            }

            Button {
                settings.openSettings(tab: .sound)
            } label: {
                Label("Sound", systemImage: "speaker.wave.2")
            }

            Divider()

            SettingsLink {
                Label("Settings…", systemImage: "gearshape")
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Taptaap", systemImage: "power")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .onAppear {
            permissions.refreshAccessStatus()
        }
    }

    @ViewBuilder
    private var switchPicker: some View {
        Picker("Switch", selection: $settings.selectedProfile) {
            ForEach(Array(SoundProfileID.profilesGroupedByBrand.enumerated()), id: \.element.brand) { index, group in
                if index > 0 {
                    Divider()
                }

                Text(group.brand)
                    .font(.body)
                    .foregroundStyle(.secondary)

                ForEach(group.profiles) { profile in
                    Label {
                        Text(profile.switchName)
                    } icon: {
                        Image(nsImage: SwitchSwatchImage.image(for: profile))
                    }
                    .tag(profile)
                }
            }
        }
        .labelsHidden()
        .pickerStyle(.inline)
    }
}

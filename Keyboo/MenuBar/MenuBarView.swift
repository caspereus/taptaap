import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared

    var body: some View {
        Group {
            if !settings.isEnabled {
                Button {
                    settings.isEnabled = true
                } label: {
                    Label("Enable Meecanico", systemImage: "keyboard")
                }
                .disabled(!permissions.hasInputMonitoringAccess)
            }

            Menu {
                switchPicker
            } label: {
                Label("Switches", systemImage: "switch.2")
            }

            Button {
                settings.openSettings(tab: .sound)
            } label: {
                Label("Sound", systemImage: "speaker.wave.2")
            }

            Menu {
                visualizerToggleButton

                Divider()

                Picker("Position", selection: $settings.visualizerPosition) {
                    ForEach(VisualizerPosition.allCases) { position in
                        Label {
                            Text(position.displayName)
                                .font(.callout)
                        } icon: {
                            Image(nsImage: VisualizerPositionImage.image(for: position))
                        }
                        .padding(.vertical, -3)
                        .tag(position)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
                .disabled(!permissions.hasInputMonitoringAccess || !settings.enableVisualizer)

                Picker("Theme", selection: $settings.visualizerTheme) {
                    ForEach(VisualizerTheme.allCases) { theme in
                        Label {
                            Text(theme.displayName)
                                .font(.callout)
                        } icon: {
                            Image(nsImage: VisualizerThemeImage.image(for: theme))
                        }
                        .padding(.vertical, -3)
                        .tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
                .disabled(!permissions.hasInputMonitoringAccess || !settings.enableVisualizer)

                Divider()

                Button {
                    settings.openSettings(tab: .visualizer)
                } label: {
                    Label("Open in Settings…", systemImage: "gearshape")
                }
            } label: {
                Label("Visualizer", systemImage: "gauge.with.dots.needle.67percent")
            }

            Divider()

            SettingsLink {
                Label("Settings…", systemImage: "gearshape")
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Meecanico", systemImage: "power")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .onAppear {
            permissions.refreshAccessStatus()
        }
    }

    private var visualizerToggleButton: some View {
        Button {
            // Apply after the menu closes so SwiftUI menu writeback cannot race UserDefaults.
            let nextValue = !settings.enableVisualizer
            Task { @MainActor in
                settings.enableVisualizer = nextValue
            }
        } label: {
            Label {
                Text(settings.enableVisualizer ? "Disable Typing Visualizer" : "Enable Typing Visualizer")
            } icon: {
                Image(systemName: settings.enableVisualizer ? "checkmark" : "eye")
            }
        }
        .disabled(!permissions.hasInputMonitoringAccess)
    }

    @ViewBuilder
    private var switchPicker: some View {
        Picker("Switch", selection: $settings.selectedProfile) {
            ForEach(Array(SoundProfileID.profilesGroupedByBrand.enumerated()), id: \.element.brand) { index, group in
                if index > 0 {
                    Divider()
                }

                Text(group.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, index == 0 ? 0 : 1)
                    .padding(.bottom, -2)

                ForEach(group.profiles) { profile in
                    Label {
                        Text(profile.switchName)
                            .font(.callout)
                    } icon: {
                        Image(nsImage: SwitchSwatchImage.image(for: profile))
                    }
                    .padding(.vertical, -3)
                    .tag(profile)
                }
            }
        }
        .labelsHidden()
        .pickerStyle(.inline)
        .controlSize(.small)
    }
}

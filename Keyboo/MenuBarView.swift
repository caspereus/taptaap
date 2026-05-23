import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if !permissions.hasInputMonitoringAccess {
                Button("Allow Input Monitoring…") {
                    permissions.requestAccess()
                    permissions.openInputMonitoringSettings()
                    openWindow(id: PermissionOnboardingWindow.id)
                }

                Divider()
            }

            Toggle("Enable Keyboo", isOn: $settings.isEnabled)
                .disabled(!permissions.hasInputMonitoringAccess)

            Divider()

            Menu {
                switchPicker
            } label: {
                Label {
                    Text("Switch")
                } icon: {
                    Image(nsImage: SwitchSwatchImage.image(for: settings.selectedProfile))
                }
            }

            Menu {
                Toggle("Show While Typing", isOn: $settings.enableVisualizer)
                    .disabled(!permissions.hasInputMonitoringAccess)

                Divider()

                Picker("Position", selection: $settings.menuBarPosition) {
                    ForEach(MenuBarPosition.allCases) { position in
                        Text(position.displayName).tag(position)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
                .disabled(!permissions.hasInputMonitoringAccess || !settings.enableVisualizer)
            } label: {
                Text("Visualizer")
            }

            Divider()

            SettingsLink {
                Text("Settings…")
            }

            Button("Quit Keyboo") {
                NSApplication.shared.terminate(nil)
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
            ForEach(SoundProfileID.profilesGroupedByBrand, id: \.brand) { group in
                Section(group.brand) {
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
        }
        .labelsHidden()
        .pickerStyle(.inline)
    }
}

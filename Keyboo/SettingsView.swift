import AppKit
import SwiftUI

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case sound
    case visualizer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .sound: "Sound"
        case .visualizer: "Visualizer"
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var launchAtLoginError: String?

    var body: some View {
        VStack(spacing: 16) {
            Picker("Settings", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        generalTab
                    case .sound:
                        soundTab
                    case .visualizer:
                        visualizerTab
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            permissions.refreshAccessStatus()
            syncLaunchAtLoginFromSystem()
            SoundEngine.shared.setOutputVolume(Float(settings.outputVolume))
        }
    }

    // MARK: - General

    @ViewBuilder
    private var generalTab: some View {
        SettingsAppHeader()

        SettingsSection(title: nil) {
            Toggle("Launch at Login", isOn: launchAtLoginBinding)

            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            SettingsStatusRow(
                title: "Input Monitoring",
                status: permissions.hasInputMonitoringAccess ? "Granted" : "Required",
                isPositive: permissions.hasInputMonitoringAccess
            )

            if !permissions.hasInputMonitoringAccess {
                HStack(spacing: 12) {
                    Button("Open System Settings") {
                        permissions.openInputMonitoringSettings()
                    }

                    Button("Request Permission") {
                        permissions.requestAccess()
                    }
                }
                .padding(.top, 4)

                PermissionXcodeDevNote()
                    .padding(.top, 4)
            }
        }

        SettingsSection(title: "Install Location") {
            SettingsValueRow(title: "Current Folder", value: InstallLocation.displayLabel)

            Text(InstallLocation.installHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        SettingsSection(title: "Privacy") {
            Text("Keyboo only reads virtual key codes to play sounds. It never captures, stores, or transmits typed text.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Sound

    @ViewBuilder
    private var soundTab: some View {
        SettingsSection(title: "Volume") {
            HStack {
                Slider(value: $settings.outputVolume, in: 0 ... 1)
                Text("\(Int(settings.outputVolume * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }

        SettingsSection(title: "Switch Profile") {
            ForEach(SoundProfileID.profilesGroupedByBrand, id: \.brand) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)

                    ForEach(group.profiles) { profile in
                        SwitchProfileRow(
                            profile: profile,
                            isSelected: settings.selectedProfile == profile
                        ) {
                            settings.selectedProfile = profile
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Visualizer

    @ViewBuilder
    private var visualizerTab: some View {
        SettingsSection(title: nil) {
            Toggle("Show While Typing", isOn: $settings.enableVisualizer)
                .disabled(!permissions.hasInputMonitoringAccess)

            Divider()

            Picker("Position", selection: $settings.menuBarPosition) {
                ForEach(MenuBarPosition.allCases) { position in
                    Text(position.displayName).tag(position)
                }
            }
            .disabled(!permissions.hasInputMonitoringAccess || !settings.enableVisualizer)
        }

        if !permissions.hasInputMonitoringAccess {
            Text("Input Monitoring permission is required to show the typing visualizer.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Launch at Login

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLogin },
            set: { newValue in
                launchAtLoginError = nil
                do {
                    try LaunchAtLoginManager.setEnabled(newValue)
                    settings.launchAtLogin = newValue
                } catch {
                    settings.launchAtLogin = LaunchAtLoginManager.isEnabled
                    launchAtLoginError = error.localizedDescription
                }
            }
        )
    }

    private func syncLaunchAtLoginFromSystem() {
        settings.launchAtLogin = LaunchAtLoginManager.isEnabled
    }
}

// MARK: - Components

private struct SettingsAppHeader: View {
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    var body: some View {
        SettingsCard {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Keyboo")
                        .font(.title2.bold())
                    Text(versionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }

            SettingsCard {
                content
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct SettingsStatusRow: View {
    let title: String
    let status: String
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(isPositive ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(status)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SwitchProfileRow: View {
    let profile: SoundProfileID
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(nsImage: SwitchSwatchImage.image(for: profile))
                    .frame(width: 18, height: 18)

                Text(profile.switchName)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}

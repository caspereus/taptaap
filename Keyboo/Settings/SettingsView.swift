import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared
    @ObservedObject private var accessibility = AccessibilityPermissionManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var launchAtLoginError: String?

    var body: some View {
        VStack(spacing: 0) {
            SettingsGlassTabBar(selection: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            tabContent
        }
        .frame(width: 480, height: 520)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onAppear {
            refreshSettingsState()
            applyRequestedSettingsTab()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            refreshSettingsState()
        }
        .onChange(of: settings.requestedSettingsTab) { _, _ in
            applyRequestedSettingsTab()
        }
    }

    private func refreshSettingsState() {
        permissions.refreshAccessStatus()
        accessibility.refreshAccessStatus()
        syncLaunchAtLoginFromSystem()
    }

    private func applyRequestedSettingsTab() {
        guard let tab = settings.requestedSettingsTab else { return }
        selectedTab = tab
        settings.requestedSettingsTab = nil
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            SettingsTabContent { generalTab }
        case .sound:
            SettingsTabContent { soundTab }
        case .visualizer:
            SettingsTabContent { visualizerTab }
        case .overlay:
            SettingsTabContent { overlayTab }
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
                    .font(.footnote)
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
                    .buttonStyle(.glass)

                    Button("Request Permission") {
                        permissions.requestAccess()
                    }
                    .buttonStyle(.glass)
                }
                .padding(.top, 4)

                PermissionXcodeDevNote()
                    .padding(.top, 4)
            }
        }

        SettingsSection(title: "Install Location") {
            SettingsValueRow(title: "Current Folder", value: InstallLocation.displayLabel)

            Text(InstallLocation.installHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        SettingsSection(title: "Privacy") {
            Text("Taptaap only reads virtual key codes to play sounds. It never captures, stores, or transmits typed text.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
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
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }

        SettingsSection(title: "Switch Profile") {
            ForEach(SoundProfileID.profilesGroupedByBrand, id: \.brand) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.brand)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
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

    private var visualizerControlsEnabled: Bool {
        permissions.hasInputMonitoringAccess && settings.enableVisualizer
    }

    @ViewBuilder
    private var visualizerTab: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Show While Typing", isOn: $settings.enableVisualizer)
                .font(.body)
                .disabled(!permissions.hasInputMonitoringAccess)

            if !permissions.hasInputMonitoringAccess {
                Text("Input Monitoring permission is required to show the typing visualizer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            Text("Position")
                .font(.body.weight(.semibold))

            VisualizerPositionPicker(
                selection: $settings.visualizerPosition,
                isEnabled: visualizerControlsEnabled
            )
        }

        VStack(alignment: .leading, spacing: 10) {
            Text("Theme")
                .font(.body.weight(.semibold))

            VisualizerThemePicker(
                selection: $settings.visualizerTheme,
                isEnabled: visualizerControlsEnabled
            )
        }
    }

    // MARK: - Keyboard Overlay

    private var overlayControlsEnabled: Bool {
        accessibility.hasAccessibilityAccess && settings.enableKeyboardOverlay
    }

    @ViewBuilder
    private var overlayTab: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Enable Keyboard Overlay", isOn: $settings.enableKeyboardOverlay)
                .font(.body)
                .disabled(!accessibility.hasAccessibilityAccess)

            if !accessibility.hasAccessibilityAccess {
                Text("Enable Accessibility permission to show keyboard overlay.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("Open System Settings") {
                        accessibility.openAccessibilitySettings()
                    }
                    .buttonStyle(.glass)

                    Button("Request Permission") {
                        accessibility.requestAccess()
                    }
                    .buttonStyle(.glass)
                }
                .padding(.top, 4)
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            Text("Show Mode")
                .font(.body.weight(.semibold))

            Picker("Show Mode", selection: $settings.overlayShowMode) {
                ForEach(OverlayShowMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!accessibility.hasAccessibilityAccess)
        }

        Toggle("Privacy Mode", isOn: $settings.overlayPrivacyMode)
            .disabled(!accessibility.hasAccessibilityAccess)

        Text("Hide normal letters unless a modifier key is held.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading, spacing: 10) {
            Text("Position")
                .font(.body.weight(.semibold))

            OverlayPositionPicker(
                selection: $settings.overlayPosition,
                isEnabled: overlayControlsEnabled
            )
        }

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Hide Delay")
                    .font(.body.weight(.semibold))
                Spacer()
                Text(String(format: "%.1fs", settings.overlayHideDelay))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: $settings.overlayHideDelay, in: 0.5 ... 3, step: 0.1)
                .disabled(!accessibility.hasAccessibilityAccess)
        }

        SettingsSection(title: "Privacy") {
            Text("Key presses are shown on screen only and are never stored, logged, or transmitted.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
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

private struct SettingsTabContent<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GlassEffectContainer(spacing: KeybooGlass.containerSpacing) {
            ScrollView {
                VStack(alignment: .leading, spacing: KeybooGlass.containerSpacing) {
                    content
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct SettingsAppHeader: View {
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Taptaap")
                        .font(.title2.weight(.semibold))
                    Text(versionText)
                        .font(.footnote)
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
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .padding(.leading, 4)
            }

            GlassCard {
                content
            }
        }
    }
}

private struct SettingsStatusRow: View {
    let title: String
    let status: String
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(isPositive ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(status)
                    .font(.subheadline)
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
                .font(.body)
            Spacer()
            Text(value)
                .font(.subheadline)
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
                    .font(.body)
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

import AppKit
import Carbon
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var launchAtLoginError: String?
    @State private var previewPressedKeyCodes: Set<CGKeyCode> = []
    @State private var previewCaptureFocused = false

    private var tabBadgeTabs: Set<SettingsTab> {
        var tabs = Set<SettingsTab>()
        if InstallLocation.needsRelocation || !permissions.hasInputMonitoringAccess {
            tabs.insert(.general)
        }
        if !permissions.hasInputMonitoringAccess {
            tabs.insert(.sound)
            tabs.insert(.visualizer)
        }
        return tabs
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsGlassTabBar(selection: $selectedTab, badgeTabs: tabBadgeTabs)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .zIndex(1)

            tabContent
                .padding(.top, 4)
                .clipped()
                .zIndex(0)
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
        }
    }

    // MARK: - General

    @ViewBuilder
    private var generalTab: some View {
        SettingsAppHeader()

        if InstallLocation.needsRelocation {
            InstallRelocationCard(showsManualOption: true)
        } else if !permissions.hasInputMonitoringAccess {
            SettingsSetupBanner(permissions: permissions)
        }

        SettingsSection(title: "General") {
            Toggle("Enable Meecanico", isOn: $settings.isEnabled)
                .disabled(!permissions.hasInputMonitoringAccess)

            if !permissions.hasInputMonitoringAccess {
                Text("Input Monitoring is required to play keyboard sounds and show the visualizer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if settings.isEnabled {
                Text("Pauses everything at once. Use the feature toggles below to turn off sound or the visualizer individually.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Meecanico is paused. Turn this on to resume your selected features.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Toggle("Keyboard Sounds", isOn: $settings.enableSound)
                .disabled(!permissions.hasInputMonitoringAccess)

            Toggle("Typing Visualizer", isOn: $settings.enableVisualizer)
                .disabled(!permissions.hasInputMonitoringAccess)

            if permissions.hasInputMonitoringAccess && settings.isEnabled {
                if !settings.enableSound && !settings.enableVisualizer {
                    Text("Both features are off — Meecanico is not listening for key presses.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !settings.enableSound {
                    Text("Keyboard sounds are off. The visualizer can still run.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !settings.enableVisualizer {
                    Text("Visualizer is off. Keyboard sounds can still play.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

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
                Button("Open System Settings") {
                    permissions.requestAccess()
                    permissions.openInputMonitoringSettings()
                }
                .buttonStyle(.glassProminent)
                .padding(.top, 4)
            }
        }

        SettingsSection(title: "Install Location") {
            SettingsValueRow(title: "Current Folder", value: InstallLocation.displayLabel)

            if InstallLocation.needsRelocation {
                InstallRelocationCard(showsManualOption: true, embedded: true)
            } else {
                Text(InstallLocation.installHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        SettingsSection(title: "Quick Hotkeys") {
            VStack(alignment: .leading, spacing: 2) {
                QuickHotkeyRow(
                    icon: "power",
                    title: "Toggle Meecanico",
                    shortcut: "Control + Option + Command + E"
                )
                QuickHotkeyRow(
                    icon: "speaker.wave.2",
                    title: "Next Sound Profile",
                    shortcut: "Control + Option + Command + Right Arrow"
                )
            }

            Text("Hotkey customization can be added in a later version.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        SettingsSection(title: "Privacy") {
            Text("Meecanico only reads virtual key codes to play sounds. It never captures, stores, or transmits typed text.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Sound

    private var soundControlsEnabled: Bool {
        permissions.hasInputMonitoringAccess && settings.enableSound
    }

    @ViewBuilder
    private var soundTab: some View {
        SettingsSection(title: "Keyboard Sounds") {
            Toggle("Enabled", isOn: $settings.enableSound)
                .disabled(!permissions.hasInputMonitoringAccess)

            if !permissions.hasInputMonitoringAccess {
                Text("Input Monitoring permission is required to play keyboard sounds.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !settings.enableSound {
                Text("Off — no switch sounds while typing. Turn on in General or here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        SettingsSection(title: "Volume") {
            HStack {
                Slider(value: $settings.outputVolume, in: 0 ... 1)
                    .disabled(!soundControlsEnabled)
                Text("\(Int(settings.outputVolume * 100))%")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
            .opacity(soundControlsEnabled ? 1 : 0.45)
        }

        SettingsSection(title: "Spatial Audio") {
            Toggle("Position keys in 3D space", isOn: $settings.enableSpatialAudio)
                .disabled(!soundControlsEnabled)

            Text("Each key plays from its position on a virtual keyboard using HRTF. Works best with headphones and mono sound samples.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(soundControlsEnabled ? 1 : 0.45)
        .allowsHitTesting(soundControlsEnabled)

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
        SettingsSection(title: "Typing Visualizer") {
            SettingsStatusRow(
                title: "Status",
                status: settings.enableVisualizer ? "On" : "Off",
                isPositive: settings.enableVisualizer
            )

            if !permissions.hasInputMonitoringAccess {
                Text("Input Monitoring permission is required to show the typing visualizer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !settings.enableVisualizer {
                Text("Off by default — turn on Typing Visualizer in the General tab when you want the overlay.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Turn off in the General tab or from the menu bar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        SettingsSection(title: "Position") {
            VisualizerPositionPicker(
                selection: $settings.visualizerPosition,
                isEnabled: visualizerControlsEnabled
            )
        }

        SettingsSection(title: "Theme") {
            VisualizerThemePicker(
                selection: $settings.visualizerTheme,
                isEnabled: visualizerControlsEnabled
            )
        }

        SettingsSection(title: "Preview") {
            KeyboardVisualizerView(
                pressedKeyCodes: previewPressedKeyCodes,
                theme: settings.visualizerTheme
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)

            VisualizerPreviewKeyCaptureView(
                isFocused: $previewCaptureFocused,
                onKeyDown: { keyCode, _ in
                    previewPressedKeyCodes.insert(keyCode)
                },
                onKeyUp: { keyCode, _ in
                    previewPressedKeyCodes.remove(keyCode)
                }
            )
            .frame(height: 44)

            Text("Click the box below and type to preview themes before enabling the overlay.")
                .font(.footnote)
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

private struct VisualizerPreviewKeyCaptureView: NSViewRepresentable {
    @Binding var isFocused: Bool
    let onKeyDown: (CGKeyCode, NSEvent.ModifierFlags) -> Void
    let onKeyUp: (CGKeyCode, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> VisualizerPreviewKeyCaptureNSView {
        let view = VisualizerPreviewKeyCaptureNSView()
        view.coordinator = context.coordinator
        view.updateFocusState(isFocused)
        return view
    }

    func updateNSView(_ nsView: VisualizerPreviewKeyCaptureNSView, context: Context) {
        nsView.coordinator = context.coordinator
        nsView.updateFocusState(isFocused)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject {
        private let parent: VisualizerPreviewKeyCaptureView

        init(_ parent: VisualizerPreviewKeyCaptureView) {
            self.parent = parent
        }

        func didFocus(_ focused: Bool) {
            DispatchQueue.main.async {
                self.parent.isFocused = focused
            }
        }

        func keyDown(_ keyCode: CGKeyCode, modifierFlags: NSEvent.ModifierFlags) {
            DispatchQueue.main.async {
                self.parent.onKeyDown(keyCode, modifierFlags)
            }
        }

        func keyUp(_ keyCode: CGKeyCode, modifierFlags: NSEvent.ModifierFlags) {
            DispatchQueue.main.async {
                self.parent.onKeyUp(keyCode, modifierFlags)
            }
        }
    }
}

private final class VisualizerPreviewKeyCaptureNSView: NSView {
    weak var coordinator: VisualizerPreviewKeyCaptureView.Coordinator?

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Click to test typing")
        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0.22).cgColor

        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted {
            coordinator?.didFocus(true)
            updateAppearance(isFocused: true)
        }
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            coordinator?.didFocus(false)
            updateAppearance(isFocused: false)
        }
        return resigned
    }

    override func keyDown(with event: NSEvent) {
        coordinator?.keyDown(CGKeyCode(event.keyCode), modifierFlags: event.modifierFlags)
    }

    override func keyUp(with event: NSEvent) {
        coordinator?.keyUp(CGKeyCode(event.keyCode), modifierFlags: event.modifierFlags)
    }

    override func flagsChanged(with event: NSEvent) {
        let modifierKeyCodes: [UInt16] = [
            UInt16(kVK_Command),
            UInt16(kVK_Shift),
            UInt16(kVK_CapsLock),
            UInt16(kVK_Option),
            UInt16(kVK_Control),
            UInt16(kVK_RightCommand),
            UInt16(kVK_RightShift),
            UInt16(kVK_RightOption),
            UInt16(kVK_RightControl),
            UInt16(kVK_Function)
        ]
        let keyCode = event.keyCode
        guard modifierKeyCodes.contains(keyCode) else { return }

        let keyCodeValue = CGKeyCode(keyCode)
        if event.modifierFlags.contains(Self.modifierFlag(for: keyCode)) {
            coordinator?.keyDown(keyCodeValue, modifierFlags: event.modifierFlags)
        } else {
            coordinator?.keyUp(keyCodeValue, modifierFlags: event.modifierFlags)
        }
    }

    func updateFocusState(_ isFocused: Bool) {
        updateAppearance(isFocused: isFocused)
    }

    private func updateAppearance(isFocused: Bool) {
        layer?.borderColor = (isFocused ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        layer?.borderWidth = isFocused ? 2 : 1
        titleLabel.stringValue = isFocused ? "Typing test active" : "Click to test typing"
    }

    private static func modifierFlag(for keyCode: UInt16) -> NSEvent.ModifierFlags {
        switch keyCode {
        case UInt16(kVK_Shift), UInt16(kVK_RightShift):
            return .shift
        case UInt16(kVK_Control), UInt16(kVK_RightControl):
            return .control
        case UInt16(kVK_Option), UInt16(kVK_RightOption):
            return .option
        case UInt16(kVK_Command), UInt16(kVK_RightCommand):
            return .command
        case UInt16(kVK_CapsLock):
            return .capsLock
        case UInt16(kVK_Function):
            return .function
        default:
            return []
        }
    }
}

// MARK: - Components

private struct SettingsSetupBanner: View {
    @ObservedObject var permissions: PermissionManager

    var body: some View {
        GlassCard {
            HStack {
                Label("Setup Required", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Spacer()

                Text("Required")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.15), in: Capsule())
            }

            Text("Meecanico needs Input Monitoring to detect key presses and play switch sounds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if permissions.hasAccessibilityOnly {
                Text("Accessibility is enabled, but Meecanico needs Input Monitoring — a separate permission.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                setupStep(number: 1, text: "Click \"Open System Settings\" below")
                setupStep(number: 2, text: "Enable Meecanico under Privacy & Security → Input Monitoring")
                setupStep(number: 3, text: "Return here — status updates automatically")
            }
            .padding(.top, 2)

            Button("Open System Settings") {
                permissions.requestAccess()
                permissions.openInputMonitoringSettings()
            }
            .buttonStyle(.glassProminent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
    }

    private func setupStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .background(.quaternary, in: Circle())

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsTabContent<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipped()
        }
    }
}

private struct SettingsAppHeader: View {
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "Version \(version)"
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Meecanico")
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
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
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

private struct QuickHotkeyRow: View {
    let icon: String
    let title: String
    let shortcut: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(title)
                .font(.body)

            Spacer(minLength: 8)

            Text(shortcut)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Divider()
                .opacity(0.45)
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

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var permissions = PermissionManager.shared

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .disabled(true)

                Text("Coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                HStack {
                    Text("Input Monitoring")
                    Spacer()
                    Text(permissions.hasInputMonitoringAccess ? "Granted" : "Required")
                        .foregroundStyle(permissions.hasInputMonitoringAccess ? Color.secondary : Color.orange)
                }

                if !permissions.hasInputMonitoringAccess {
                    PermissionXcodeDevNote()

                    Button("Open System Settings") {
                        permissions.openInputMonitoringSettings()
                    }

                    Button("Request Permission") {
                        permissions.requestAccess()
                    }
                }
            }

            Section("Privacy") {
                Text("Keyboo only reads virtual key codes to play sounds. It never captures, stores, or transmits typed text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .onAppear {
            permissions.refreshAccessStatus()
        }
    }
}

#Preview {
    SettingsView()
}

import AppKit
import SwiftUI

struct PermissionOnboardingView: View {
    @ObservedObject private var permissions = PermissionManager.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 480)
        .background(.background)
        .onAppear {
            NSApplication.shared.activate(ignoringOtherApps: true)
            permissions.refreshAccessStatus()
        }
        .onChange(of: permissions.hasInputMonitoringAccess) { _, granted in
            if granted && !InstallLocation.needsRelocation {
                completeOnboarding()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Welcome to Taptaap")
                .font(.title2.weight(.semibold))

            Text("Mechanical keyboard sounds for every key you press.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            if InstallLocation.needsRelocation {
                InstallRelocationCard()
            } else {
                permissionCard
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Your privacy", systemImage: "lock.shield")
                    .font(.headline)

                Text("Taptaap only reads virtual key codes to play sounds. It never captures, stores, or transmits what you type.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
    }

    private var permissionCard: some View {
        GlassCard {
            HStack {
                Label("Input Monitoring", systemImage: "hand.tap")
                    .font(.headline)

                Spacer()

                statusBadge
            }

            Text("Taptaap needs this permission to detect key presses system-wide and play switch sounds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !permissions.hasInputMonitoringAccess {
                VStack(alignment: .leading, spacing: 6) {
                    if permissions.hasAccessibilityOnly {
                        Text("Accessibility is enabled, but Taptaap needs Input Monitoring — a separate permission.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    onboardingStep(number: 1, text: "Click \"Open System Settings\" below")
                    onboardingStep(number: 2, text: "Enable Taptaap under Privacy & Security → Input Monitoring")
                    onboardingStep(number: 3, text: "Return here — Taptaap will start automatically")
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if permissions.hasInputMonitoringAccess {
            Label("Granted", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
        } else {
            Text("Required")
                .font(.caption.weight(.medium))
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.orange.opacity(0.15), in: Capsule())
        }
    }

    private func onboardingStep(number: Int, text: String) -> some View {
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

    private var footer: some View {
        HStack {
            if InstallLocation.needsRelocation {
                Button("Skip for Now") {
                    completeOnboarding()
                }
                .buttonStyle(.glass)
                .keyboardShortcut(.cancelAction)
            } else {
                Button("Skip for Now") {
                    completeOnboarding()
                }
                .buttonStyle(.glass)
                .keyboardShortcut(.cancelAction)

                Spacer()

                if permissions.hasInputMonitoringAccess {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
                } else {
                    Button("Open System Settings") {
                        permissions.requestAccess()
                        permissions.openInputMonitoringSettings()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                }
            }
        }
        .padding(20)
    }

    private func completeOnboarding() {
        settings.hasCompletedPermissionOnboarding = true
        dismissWindow(id: PermissionOnboardingWindow.id)
    }
}

enum PermissionOnboardingWindow {
    static let id = "permission-onboarding"
}

#Preview {
    PermissionOnboardingView()
        .frame(height: 520)
}

import SwiftUI

struct InstallRelocationCard: View {
    var showsManualOption = true
    var embedded = false
    @State private var isMoving = false
    @State private var moveError: String?

    var body: some View {
        Group {
            if embedded {
                cardContent
            } else {
                GlassCard {
                    cardContent
                }
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !embedded {
                HStack {
                    Label("Install Location", systemImage: "folder")
                        .font(.headline)

                    Spacer()

                    Text("Recommended")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.15), in: Capsule())
                }
            }

            DragToApplicationsPrompt(style: embedded ? .compact : .full)
                .frame(maxWidth: .infinity)

            if embedded {
                Text("Meecanico is running from \"\(InstallLocation.displayLabel)\". Drag it to Applications before granting Input Monitoring.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Meecanico is running from \"\(InstallLocation.displayLabel)\". Install to Applications so Input Monitoring stays linked to the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !embedded {
                VStack(alignment: .leading, spacing: 6) {
                    installStep(number: 1, text: "Click \"Open Finder\" and drag Meecanico to Applications")
                    installStep(number: 2, text: "Open Meecanico from Applications")
                    installStep(number: 3, text: "Then enable Input Monitoring in System Settings")
                }
            }

            if let moveError {
                Text(moveError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if showsManualOption {
                Button {
                    InstallLocation.revealForManualInstall()
                } label: {
                    Label("Open Finder", systemImage: "folder")
                }
                .buttonStyle(.glassProminent)
                .disabled(isMoving)
            }

            Button {
                Task { await performMove() }
            } label: {
                if isMoving {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Move to Applications Automatically")
                }
            }
            .modifier(AutomaticMoveButtonStyle(isPrimary: !showsManualOption))
            .disabled(isMoving)
        }
    }

    private struct AutomaticMoveButtonStyle: ViewModifier {
        let isPrimary: Bool

        func body(content: Content) -> some View {
            if isPrimary {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        }
    }

    private func installStep(number: Int, text: String) -> some View {
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

    private func performMove() async {
        isMoving = true
        moveError = nil
        defer { isMoving = false }

        do {
            try await InstallLocation.moveToApplications()
        } catch {
            moveError = error.localizedDescription
        }
    }
}

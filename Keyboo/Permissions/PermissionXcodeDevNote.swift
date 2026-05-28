import SwiftUI

/// Shown only in Debug builds to explain Xcode rebuild permission behavior.
struct PermissionXcodeDevNote: View {
    var body: some View {
        #if DEBUG
        Text("Running from Xcode? Rebuilds can reset Input Monitoring until the app is signed with a Development Team. Re-enable Taptaap in System Settings after each Run if needed.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        #else
        EmptyView()
        #endif
    }
}

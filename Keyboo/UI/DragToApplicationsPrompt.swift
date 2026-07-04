import AppKit
import SwiftUI

struct DragToApplicationsPrompt: View {
    enum Style {
        case full
        case compact
    }

    var style: Style = .full

    private var iconSize: CGFloat {
        style == .full ? 64 : 44
    }

    private var appIcon: NSImage {
        NSApplication.shared.applicationIconImage
    }

    private var applicationsIcon: NSImage {
        NSWorkspace.shared.icon(forFile: "/Applications")
    }

    var body: some View {
        VStack(spacing: style == .full ? 10 : 8) {
            HStack(spacing: style == .full ? 20 : 14) {
                installTarget(icon: appIcon, label: "Taptaap")

                dragArrow

                installTarget(icon: applicationsIcon, label: "Applications")
            }
            .frame(maxWidth: .infinity)

            Text("Drag Taptaap to the Applications folder")
                .font(style == .full ? .subheadline.weight(.medium) : .footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, style == .full ? 8 : 4)
    }

    private func installTarget(icon: NSImage, label: String) -> some View {
        VStack(spacing: 6) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: iconSize, height: iconSize)

            Text(label)
                .font(style == .full ? .caption : .caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(minWidth: iconSize + 8)
    }

    private var dragArrow: some View {
        Image(systemName: "arrow.right")
            .font(style == .full ? .title2.weight(.semibold) : .body.weight(.semibold))
            .foregroundStyle(.tertiary)
            .symbolEffect(.pulse, options: .repeating)
            .accessibilityHidden(true)
    }
}

#Preview {
    DragToApplicationsPrompt()
        .padding()
        .frame(width: 400)
}

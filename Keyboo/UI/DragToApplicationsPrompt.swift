import AppKit
import SwiftUI

struct DragToApplicationsPrompt: View {
    enum Style {
        case full
        case compact
    }

    var style: Style = .full

    private var iconSize: CGFloat {
        style == .full ? 88 : 56
    }

    private var containerMaxWidth: CGFloat {
        style == .full ? 292 : 248
    }

    private var iconRowSpacing: CGFloat {
        style == .full ? 14 : 10
    }

    private var appIcon: NSImage {
        NSApplication.shared.applicationIconImage
    }

    private var applicationsIcon: NSImage {
        NSWorkspace.shared.icon(forFile: "/Applications")
    }

    var body: some View {
        VStack(spacing: style == .full ? 12 : 8) {
            HStack(spacing: iconRowSpacing) {
                installTarget(icon: appIcon, label: "Meecanico")

                dragArrow

                installTarget(icon: applicationsIcon, label: "Applications")
            }

            Text("Drag Meecanico to the Applications folder")
                .font(style == .full ? .subheadline.weight(.medium) : .footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, style == .full ? 18 : 14)
        .padding(.vertical, style == .full ? 16 : 12)
        .frame(maxWidth: containerMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private func installTarget(icon: NSImage, label: String) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: iconSize, height: iconSize)

            Text(label)
                .font(style == .full ? .caption : .caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: iconSize)
    }

    private var dragArrow: some View {
        Image(systemName: "arrow.right")
            .font(style == .full ? .title.weight(.semibold) : .headline.weight(.semibold))
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

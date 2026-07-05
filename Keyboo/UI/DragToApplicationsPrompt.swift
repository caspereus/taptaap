import AppKit
import SwiftUI

struct DragToApplicationsPrompt: View {
    enum Style {
        case full
        case compact
    }

    var style: Style = .full

    private var iconSize: CGFloat {
        style == .full ? 48 : 36
    }

    private var containerMaxWidth: CGFloat {
        style == .full ? 196 : 168
    }

    private var iconRowSpacing: CGFloat {
        style == .full ? 6 : 4
    }

    private var appIcon: NSImage {
        NSApplication.shared.applicationIconImage
    }

    private var applicationsIcon: NSImage {
        NSWorkspace.shared.icon(forFile: "/Applications")
    }

    var body: some View {
        HStack(spacing: iconRowSpacing) {
            installTarget(icon: appIcon, label: "Meecanico")

            dragArrow

            installTarget(icon: applicationsIcon, label: "Applications")
        }
        .padding(.horizontal, style == .full ? 10 : 8)
        .padding(.vertical, style == .full ? 8 : 6)
        .frame(maxWidth: containerMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private func installTarget(icon: NSImage, label: String) -> some View {
        VStack(spacing: 4) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: iconSize, height: iconSize)

            Text(label)
                .font(style == .full ? .caption : .caption2)
                .foregroundStyle(.black.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: iconSize)
    }

    private var dragArrow: some View {
        Image(systemName: "arrow.right")
            .font(style == .full ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
            .foregroundStyle(.black.opacity(0.35))
            .symbolEffect(.pulse, options: .repeating)
            .accessibilityHidden(true)
    }
}

#Preview {
    DragToApplicationsPrompt()
        .padding()
        .frame(width: 400)
}

import AppKit
import SwiftUI

struct SwitchSwatchView: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay {
                Image(systemName: "plus")
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundStyle(crossColor)
            }
    }

    private var crossColor: Color {
        color.prefersDarkForeground ? Color.black.opacity(0.55) : Color.white.opacity(0.92)
    }
}

@MainActor
enum SwitchSwatchImage {
    private static var cache: [SoundProfileID: NSImage] = [:]

    static func image(for profile: SoundProfileID) -> NSImage {
        if let cached = cache[profile] {
            return cached
        }

        let renderer = ImageRenderer(content: SwitchSwatchView(color: profile.swatchColor))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2

        let image = renderer.nsImage ?? NSImage(size: NSSize(width: 14, height: 14))
        image.isTemplate = false
        cache[profile] = image
        return image
    }
}

private extension Color {
    var prefersDarkForeground: Bool {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return false }
        let luminance = 0.299 * rgb.redComponent
            + 0.587 * rgb.greenComponent
            + 0.114 * rgb.blueComponent
        return luminance > 0.62
    }
}

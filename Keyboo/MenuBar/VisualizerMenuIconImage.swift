import AppKit
import SwiftUI

@MainActor
enum VisualizerPositionImage {
    private static var cache: [VisualizerPosition: NSImage] = [:]

    static func image(for position: VisualizerPosition) -> NSImage {
        if let cached = cache[position] {
            return cached
        }

        let content: AnyView = if position.isFollowCursor {
            AnyView(
                Image(systemName: "cursorarrow")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 16, height: 14)
            )
        } else {
            AnyView(
                VisualizerPositionIcon(position: position)
                    .frame(width: 24, height: 16)
            )
        }

        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2

        let image = renderer.nsImage ?? NSImage(size: NSSize(width: 16, height: 14))
        image.isTemplate = position.isFollowCursor
        cache[position] = image
        return image
    }
}

@MainActor
enum VisualizerThemeImage {
    private static var cache: [VisualizerTheme: NSImage] = [:]

    static func image(for theme: VisualizerTheme) -> NSImage {
        if let cached = cache[theme] {
            return cached
        }

        let renderer = ImageRenderer(
            content: VisualizerThemeSwatch(theme: theme, isSelected: false)
                .frame(width: 20, height: 14)
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2

        let image = renderer.nsImage ?? NSImage(size: NSSize(width: 20, height: 14))
        image.isTemplate = false
        cache[theme] = image
        return image
    }
}

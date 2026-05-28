import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<KeyboardOverlayView>?
    private var currentKeycaps: [String] = []
    private var currentTheme: OverlayTheme = .graphite

    private let edgeMargin: CGFloat = 24
    private let bottomMargin: CGFloat = 72
    private let topMargin: CGFloat = 48

    func show(keycaps: [String], position: OverlayPosition, theme: OverlayTheme) {
        ensurePanel(with: keycaps, theme: theme)
        currentKeycaps = keycaps
        currentTheme = theme
        reposition(to: position)
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func updatePosition(_ position: OverlayPosition) {
        guard panel?.isVisible == true else { return }
        reposition(to: position)
    }

    private func ensurePanel(with keycaps: [String], theme: OverlayTheme) {
        if panel == nil {
            let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            panel.hidesOnDeactivate = false
            panel.becomesKeyOnlyIfNeeded = false
            self.panel = panel
        }

        if hostingView == nil || currentKeycaps != keycaps || currentTheme != theme {
            let hostingView = NSHostingView(rootView: KeyboardOverlayView(keycaps: keycaps, theme: theme))
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            panel?.contentView = hostingView
            self.hostingView = hostingView
            hostingView.invalidateIntrinsicContentSize()
        }
    }

    private func reposition(to position: OverlayPosition) {
        guard let panel, let hostingView else { return }

        hostingView.invalidateIntrinsicContentSize()
        hostingView.layoutSubtreeIfNeeded()
        let fittingSize = hostingView.fittingSize
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let originX = visibleFrame.midX - fittingSize.width / 2

        let originY: CGFloat
        switch position {
        case .bottomCenter:
            originY = visibleFrame.minY + bottomMargin
        case .topCenter:
            originY = visibleFrame.maxY - fittingSize.height - topMargin
        case .center:
            originY = visibleFrame.midY - fittingSize.height / 2
        }

        panel.setFrame(
            NSRect(
                x: originX,
                y: originY,
                width: fittingSize.width,
                height: fittingSize.height
            ),
            display: true
        )
    }
}

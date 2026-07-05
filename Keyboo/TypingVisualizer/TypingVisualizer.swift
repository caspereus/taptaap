import AppKit
import Combine
import CoreGraphics
import SwiftUI

@MainActor
final class TypingVisualizer: ObservableObject {
    static let shared = TypingVisualizer()

    private static let horizontalPadding: CGFloat = 28
    private static let verticalPadding: CGFloat = 36

    static var panelSize: NSSize {
        let keyboard = KeyboardLayout.contentSize
        return NSSize(
            width: keyboard.width + horizontalPadding,
            height: keyboard.height + verticalPadding
        )
    }

    @Published private(set) var pressedKeyCodes: Set<CGKeyCode> = []
    @Published private(set) var theme: VisualizerTheme = .arctic

    private var panel: NSPanel?
    private var position: VisualizerPosition = .bottomCenter
    private var isVisible = false
    private var keyReleaseTimers: [CGKeyCode: Timer] = [:]
    private var cursorTrackingTimer: Timer?

    private let edgeMargin: CGFloat = 24
    private let bottomMargin: CGFloat = 72
    private let topMargin: CGFloat = 12
    private let cursorOffset: CGFloat = 20
    private let keyReleaseFallback: TimeInterval = 0.12

    private init() {}

    func setActive(_ active: Bool, position: VisualizerPosition, theme: VisualizerTheme) {
        self.position = position
        self.theme = theme
        isVisible = active

        if active {
            showPanel()
            syncCursorTracking()
        } else {
            hidePanel()
            resetState()
        }
    }

    func updatePosition(_ position: VisualizerPosition) {
        self.position = position
        guard isVisible else { return }
        syncCursorTracking()
        repositionPanel()
    }

    func updateTheme(_ theme: VisualizerTheme) {
        self.theme = theme
    }

    func recordKeyDown(keyCode: CGKeyCode) {
        guard isVisible else { return }

        pressedKeyCodes.insert(keyCode)
        scheduleKeyRelease(for: keyCode)

        if position.isFollowCursor {
            repositionPanel()
        }
    }

    func recordKeyUp(keyCode: CGKeyCode) {
        guard isVisible else { return }
        releaseKey(keyCode)
    }

    private func resetState() {
        stopCursorTracking()
        cancelAllKeyReleaseTimers()
        pressedKeyCodes.removeAll()
    }

    private func scheduleKeyRelease(for keyCode: CGKeyCode) {
        keyReleaseTimers[keyCode]?.invalidate()
        keyReleaseTimers[keyCode] = Timer.scheduledTimer(
            withTimeInterval: keyReleaseFallback,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.releaseKey(keyCode)
            }
        }
    }

    private func releaseKey(_ keyCode: CGKeyCode) {
        keyReleaseTimers[keyCode]?.invalidate()
        keyReleaseTimers[keyCode] = nil
        pressedKeyCodes.remove(keyCode)
    }

    private func cancelAllKeyReleaseTimers() {
        keyReleaseTimers.values.forEach { $0.invalidate() }
        keyReleaseTimers.removeAll()
    }

    private func syncCursorTracking() {
        if isVisible && position.isFollowCursor {
            startCursorTracking()
        } else {
            stopCursorTracking()
        }
    }

    private func startCursorTracking() {
        guard cursorTrackingTimer == nil else { return }
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.repositionPanel()
            }
        }
    }

    private func stopCursorTracking() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
    }

    private func showPanel() {
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: Self.panelSize),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            panel.hidesOnDeactivate = false

            let hostingView = NSHostingView(
                rootView: TypingVisualizerView(visualizer: self)
            )
            panel.contentView = hostingView
            self.panel = panel
        }

        let size = Self.panelSize
        if let hostingView = panel?.contentView as? NSHostingView<TypingVisualizerView> {
            hostingView.frame = NSRect(origin: .zero, size: size)
        }

        repositionPanel()
        panel?.orderFrontRegardless()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    private func repositionPanel() {
        guard let panel else { return }

        if position.isFollowCursor {
            repositionToCursor(on: screenContainingMouse())
            return
        }

        guard let screen = NSScreen.main else { return }
        let frame = fixedFrame(for: position, on: screen)
        panel.setFrame(frame, display: true)
    }

    private func repositionToCursor(on screen: NSScreen?) {
        guard let panel, let screen else { return }

        let visibleFrame = screen.visibleFrame
        let mouse = NSEvent.mouseLocation
        let panelWidth = Self.panelSize.width
        let panelHeight = Self.panelSize.height

        var originX = mouse.x + cursorOffset
        var originY = mouse.y - panelHeight - cursorOffset

        originX = min(max(originX, visibleFrame.minX + 8), visibleFrame.maxX - panelWidth - 8)
        originY = min(max(originY, visibleFrame.minY + 8), visibleFrame.maxY - panelHeight - 8)

        panel.setFrame(
            NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight),
            display: true
        )
    }

    private func fixedFrame(for position: VisualizerPosition, on screen: NSScreen) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let panelWidth = Self.panelSize.width
        let panelHeight = Self.panelSize.height

        let origin: CGPoint
        switch position {
        case .topLeft:
            origin = CGPoint(x: visibleFrame.minX + edgeMargin, y: visibleFrame.maxY - panelHeight - topMargin)
        case .topCenter:
            origin = CGPoint(x: visibleFrame.midX - panelWidth / 2, y: visibleFrame.maxY - panelHeight - topMargin)
        case .topRight:
            origin = CGPoint(x: visibleFrame.maxX - panelWidth - edgeMargin, y: visibleFrame.maxY - panelHeight - topMargin)
        case .bottomLeft:
            origin = CGPoint(x: visibleFrame.minX + edgeMargin, y: visibleFrame.minY + bottomMargin)
        case .bottomCenter:
            origin = CGPoint(x: visibleFrame.midX - panelWidth / 2, y: visibleFrame.minY + bottomMargin)
        case .bottomRight:
            origin = CGPoint(x: visibleFrame.maxX - panelWidth - edgeMargin, y: visibleFrame.minY + bottomMargin)
        case .followCursor:
            fatalError("followCursor is handled by repositionToCursor")
        }

        return NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight))
    }

    private func screenContainingMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }
}

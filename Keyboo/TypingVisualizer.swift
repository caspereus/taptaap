import AppKit
import Combine
import CoreGraphics
import SwiftUI

@MainActor
final class TypingVisualizer: ObservableObject {
    static let shared = TypingVisualizer()
    static let panelSize = NSSize(width: 260, height: 52)

    @Published private(set) var currentWPM: Int = 0
    @Published private(set) var currentKPM: Int = 0
    @Published private(set) var accentColor: Color = SoundProfileID.default.swatchColor

    private var panel: NSPanel?
    private var position: MenuBarPosition = .center
    private var isVisible = false
    private var keystrokeTimestamps: [Date] = []
    private var idleTimer: Timer?

    private let windowDuration: TimeInterval = 10
    private let minimumElapsed: TimeInterval = 0.5

    private init() {}

    func setActive(_ active: Bool, position: MenuBarPosition, accentColor: Color) {
        self.position = position
        self.accentColor = accentColor
        isVisible = active

        if active {
            showPanel()
            startIdleTimer()
        } else {
            hidePanel()
            resetSpeedTracking()
        }
    }

    func updatePosition(_ position: MenuBarPosition) {
        self.position = position
        repositionPanel()
    }

    func updateAccentColor(_ color: Color) {
        accentColor = color
    }

    func recordKeystroke(keyCode: CGKeyCode) {
        guard isVisible, KeyCodeMapper.countsTowardTypingSpeed(for: keyCode) else { return }

        let now = Date()
        keystrokeTimestamps.append(now)
        pruneSamples(before: now)
        recomputeSpeed(at: now)
        startIdleTimer()
    }

    private func resetSpeedTracking() {
        stopIdleTimer()
        keystrokeTimestamps.removeAll()
        currentWPM = 0
        currentKPM = 0
    }

    private func pruneSamples(before now: Date) {
        let cutoff = now.addingTimeInterval(-windowDuration)
        keystrokeTimestamps.removeAll { $0 < cutoff }
    }

    private func recomputeSpeed(at now: Date) {
        guard !keystrokeTimestamps.isEmpty else {
            currentWPM = 0
            currentKPM = 0
            return
        }

        let oldest = keystrokeTimestamps[0]
        let elapsed = max(now.timeIntervalSince(oldest), minimumElapsed)
        let kpm = Double(keystrokeTimestamps.count) / elapsed * 60.0
        currentKPM = Int(kpm.rounded())
        currentWPM = Int((kpm / 5.0).rounded())
    }

    private func startIdleTimer() {
        stopIdleTimer()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isVisible else { return }
                let now = Date()
                self.pruneSamples(before: now)
                self.recomputeSpeed(at: now)
            }
        }
    }

    private func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
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
            panel.hasShadow = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            panel.hidesOnDeactivate = false

            let hostingView = NSHostingView(
                rootView: TypingVisualizerView(visualizer: self)
            )
            hostingView.frame = NSRect(origin: .zero, size: Self.panelSize)
            panel.contentView = hostingView
            self.panel = panel
        }

        repositionPanel()
        panel?.orderFrontRegardless()
    }

    private func hidePanel() {
        stopIdleTimer()
        panel?.orderOut(nil)
    }

    private func repositionPanel() {
        guard let panel, let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let panelWidth = Self.panelSize.width
        let panelHeight = Self.panelSize.height
        let bottomMargin: CGFloat = 72

        let originX: CGFloat
        switch position {
        case .left:
            originX = visibleFrame.minX + 24
        case .center:
            originX = visibleFrame.midX - panelWidth / 2
        case .right:
            originX = visibleFrame.maxX - panelWidth - 24
        }

        let originY = visibleFrame.minY + bottomMargin
        panel.setFrame(
            NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight),
            display: true
        )
    }
}

import CoreGraphics
import Foundation

/// Global keyboard listener using CGEventTap.
///
/// Privacy: This monitor reads only the virtual key code from keyDown events
/// (`.keyboardEventKeycode`). It never reads typed characters, key combinations
/// for text capture, clipboard content, or any other sensitive input data.
/// Key codes are used solely to select and play sound effects.
final class KeyboardEventMonitor {
    static let shared = KeyboardEventMonitor()

    private var tapThread: Thread?
    private var runLoop: CFRunLoop?
    private var eventTap: CFMachPort?
    private var isRunning = false

    private let stateLock = NSLock()
    private var monitoringActive = false

    private init() {}

    func setMonitoringActive(_ active: Bool) {
        stateLock.lock()
        monitoringActive = active
        stateLock.unlock()
    }

    private func isMonitoringActive() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return monitoringActive
    }

    func start() {
        guard !isRunning else { return }
        guard CGPreflightListenEventAccess() else { return }

        isRunning = true
        let thread = Thread { [weak self] in
            self?.runEventTap(on: Thread.current)
        }
        thread.name = "Keyboo.EventTap"
        tapThread = thread
        thread.start()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        if let runLoop {
            CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue) { [weak self] in
                if let eventTap = self?.eventTap {
                    CGEvent.tapEnable(tap: eventTap, enable: false)
                }
                CFRunLoopStop(runLoop)
            }
            CFRunLoopWakeUp(runLoop)
        }

        tapThread = nil
        runLoop = nil
        eventTap = nil
    }

    func restartIfNeeded() {
        stop()
        start()
    }

    private func runEventTap(on thread: Thread) {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard type == .keyDown, let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let monitor = Unmanaged<KeyboardEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            guard monitor.isMonitoringActive() else {
                return Unmanaged.passUnretained(event)
            }

            // Privacy: only the virtual key code is read — never typed text.
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            SoundEngine.shared.play(keyCode: keyCode)

            DispatchQueue.main.async {
                Task { @MainActor in
                    TypingVisualizer.shared.recordKeystroke(keyCode: keyCode)
                }
            }

            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            isRunning = false
            return
        }

        eventTap = tap
        runLoop = CFRunLoopGetCurrent()

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        while isRunning {
            CFRunLoopRunInMode(.defaultMode, 0.25, true)
        }

        if let source {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: false)
        eventTap = nil
    }
}

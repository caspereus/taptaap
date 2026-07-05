import AppKit
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
        stateLock.lock()
        guard !isRunning else {
            stateLock.unlock()
            return
        }
        stateLock.unlock()

        waitForTapThreadToFinish()

        stateLock.lock()
        guard !isRunning else {
            stateLock.unlock()
            return
        }
        guard CGPreflightListenEventAccess() else {
            stateLock.unlock()
            return
        }

        isRunning = true
        let thread = Thread { [weak self] in
            self?.runEventTap(on: Thread.current)
        }
        thread.name = "Keyboo.EventTap"
        tapThread = thread
        stateLock.unlock()

        thread.start()
    }

    func stop() {
        stateLock.lock()
        guard isRunning else {
            stateLock.unlock()
            return
        }
        isRunning = false
        let loop = runLoop
        let thread = tapThread
        stateLock.unlock()

        if let loop {
            CFRunLoopPerformBlock(loop, CFRunLoopMode.commonModes.rawValue) {
                CFRunLoopStop(loop)
            }
            CFRunLoopWakeUp(loop)
        }

        waitForThreadToFinish(thread)

        stateLock.lock()
        if tapThread === thread {
            tapThread = nil
            runLoop = nil
        }
        stateLock.unlock()
    }

    func restartIfNeeded() {
        stop()
        start()
    }

    private func waitForTapThreadToFinish() {
        stateLock.lock()
        let thread = tapThread
        stateLock.unlock()
        waitForThreadToFinish(thread)
    }

    private func waitForThreadToFinish(_ thread: Thread?) {
        guard let thread else { return }
        while !thread.isFinished {
            Thread.sleep(forTimeInterval: 0.001)
        }
    }

    private func runEventTap(on thread: Thread) {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let monitor = Unmanaged<KeyboardEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            guard monitor.isMonitoringActive() else {
                return Unmanaged.passUnretained(event)
            }

            // Privacy: only the virtual key code is read — never typed text.
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

            if type == .keyDown {
                SoundEngine.shared.play(keyCode: keyCode)
                Task { @MainActor in
                    TypingVisualizer.shared.recordKeyDown(keyCode: keyCode)
                }
            } else if type == .keyUp {
                Task { @MainActor in
                    TypingVisualizer.shared.recordKeyUp(keyCode: keyCode)
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
            stateLock.lock()
            isRunning = false
            tapThread = nil
            runLoop = nil
            stateLock.unlock()
            return
        }

        let currentRunLoop = CFRunLoopGetCurrent()
        stateLock.lock()
        runLoop = currentRunLoop
        stateLock.unlock()

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(currentRunLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        while true {
            stateLock.lock()
            let running = isRunning
            stateLock.unlock()
            guard running else { break }
            CFRunLoopRunInMode(.defaultMode, 0.25, true)
        }

        CGEvent.tapEnable(tap: tap, enable: false)
        if let source {
            CFRunLoopRemoveSource(currentRunLoop, source, .commonModes)
        }

        stateLock.lock()
        if runLoop === currentRunLoop {
            runLoop = nil
        }
        if tapThread === thread {
            tapThread = nil
        }
        stateLock.unlock()
    }
}

#if DEBUG
extension KeyboardEventMonitor {
    var isEventTapRunningForTesting: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return isRunning
    }

    /// Pretends the event tap is already running (sound on, visualizer off scenario).
    func simulateRunningEventTapForTesting(on thread: Thread) {
        stateLock.lock()
        isRunning = true
        tapThread = thread
        stateLock.unlock()
    }

    func resetForTesting() {
        stateLock.lock()
        isRunning = false
        tapThread = nil
        runLoop = nil
        monitoringActive = false
        stateLock.unlock()
    }
}
#endif

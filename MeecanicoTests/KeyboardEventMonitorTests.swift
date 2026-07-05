import XCTest
@testable import Meecanico

final class KeyboardEventMonitorTests: XCTestCase {
    private var keepDummyThreadAlive = false
    private var dummyThread: Thread?

    override func tearDown() {
        keepDummyThreadAlive = false
        if let dummyThread {
            let deadline = Date().addingTimeInterval(1)
            while dummyThread.isExecuting, Date() < deadline {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        dummyThread = nil
        KeyboardEventMonitor.shared.resetForTesting()
        super.tearDown()
    }

    /// Regression: with keyboard sounds already running, enabling the visualizer calls
    /// `start()` again. It must return immediately instead of waiting forever on the tap thread.
    func testStartReturnsImmediatelyWhenEventTapAlreadyRunning() {
        let monitor = KeyboardEventMonitor.shared
        monitor.resetForTesting()

        let threadReady = DispatchSemaphore(value: 0)
        keepDummyThreadAlive = true
        let thread = Thread {
            threadReady.signal()
            while self.keepDummyThreadAlive {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        dummyThread = thread
        thread.start()
        threadReady.wait()

        monitor.simulateRunningEventTapForTesting(on: thread)
        XCTAssertTrue(monitor.isEventTapRunningForTesting)

        let completed = expectation(description: "redundant start completes")
        DispatchQueue.global(qos: .userInitiated).async {
            monitor.start()
            completed.fulfill()
        }

        wait(for: [completed], timeout: 0.25)
        XCTAssertTrue(monitor.isEventTapRunningForTesting)
    }

    func testSyncKeyboardMonitorPathDoesNotBlockWhenMonitorAlreadyRunning() {
        let monitor = KeyboardEventMonitor.shared
        monitor.resetForTesting()

        let threadReady = DispatchSemaphore(value: 0)
        keepDummyThreadAlive = true
        let thread = Thread {
            threadReady.signal()
            while self.keepDummyThreadAlive {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        dummyThread = thread
        thread.start()
        threadReady.wait()

        monitor.simulateRunningEventTapForTesting(on: thread)
        monitor.setMonitoringActive(true)

        let completed = expectation(description: "visualizer toggle path completes")
        DispatchQueue.global(qos: .userInitiated).async {
            // Mirrors SettingsServiceCoordinator.syncKeyboardMonitor() when sound is on
            // and the user enables the visualizer: monitoring stays active, start() is called.
            monitor.setMonitoringActive(true)
            monitor.start()
            completed.fulfill()
        }

        wait(for: [completed], timeout: 0.25)
        XCTAssertTrue(monitor.isEventTapRunningForTesting)
    }
}

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        enforceSingleInstance()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            SettingsServiceCoordinator.shared.start()
        }
    }

    private func enforceSingleInstance() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let otherInstances = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != currentPID }

        guard !otherInstances.isEmpty else { return }

        #if DEBUG
        // Replace the previous Xcode run with the newly built instance.
        otherInstances.forEach { $0.forceTerminate() }
        if !otherInstances.isEmpty {
            Thread.sleep(forTimeInterval: 0.2)
        }
        #else
        otherInstances.first?.activate(options: [.activateIgnoringOtherApps])
        NSApp.terminate(nil)
        #endif
    }
}

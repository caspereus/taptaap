import AppKit
import Foundation

enum InstallLocation {
    static var displayLabel: String {
        let path = Bundle.main.bundlePath

        if isInApplications {
            return "Applications"
        }

        let lowercased = path.lowercased()
        if lowercased.contains("/deriveddata/")
            || lowercased.contains("/build/products/")
            || lowercased.contains("/.build/") {
            return "Debug"
        }

        if lowercased.contains("/xcode/") || lowercased.contains("/developer/") {
            return "Development"
        }

        return URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
    }

    static var isInApplications: Bool {
        let path = Bundle.main.bundlePath
        if path.hasPrefix("/Applications/") {
            return true
        }

        let userApplications = (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
        return path.hasPrefix(userApplications + "/")
    }

    static var isDevelopmentBuild: Bool {
        #if DEBUG
        return true
        #else
        let lowercased = Bundle.main.bundlePath.lowercased()
        return lowercased.contains("/deriveddata/")
            || lowercased.contains("/build/products/")
            || lowercased.contains("/.build/")
            || lowercased.contains("/xcode/")
            || lowercased.contains("/developer/")
        #endif
    }

    static var needsRelocation: Bool {
        !isInApplications && !isDevelopmentBuild
    }

    static var applicationsDestinationURL: URL {
        URL(fileURLWithPath: "/Applications", isDirectory: true)
            .appendingPathComponent(Bundle.main.bundleURL.lastPathComponent, isDirectory: true)
    }

    static let installHint =
        "Keeping Meecanico in Applications makes Input Monitoring setup more predictable."

    static func revealApplicationsFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Applications")
    }

    /// Opens Finder with Meecanico selected and the Applications folder visible for drag-and-drop install.
    static func revealForManualInstall() {
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([appURL])
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications", isDirectory: true))
    }

    @MainActor
    static func moveToApplications() async throws {
        guard needsRelocation else {
            throw MoveError.notNeeded
        }

        let sourceURL = Bundle.main.bundleURL
        let destinationURL = applicationsDestinationURL
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.trashItem(at: destinationURL, resultingItemURL: nil)
        }

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw MoveError.copyFailed(error.localizedDescription)
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: destinationURL, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: MoveError.launchFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }

        NSApp.terminate(nil)
    }

    enum MoveError: LocalizedError {
        case notNeeded
        case copyFailed(String)
        case launchFailed(String)

        var errorDescription: String? {
            switch self {
            case .notNeeded:
                return "Meecanico is already in Applications."
            case .copyFailed(let message):
                return "Could not copy Meecanico to Applications. \(message)"
            case .launchFailed(let message):
                return "Copied Meecanico to Applications, but could not open it. Open it manually from Applications. \(message)"
            }
        }
    }
}

import Foundation

enum InstallLocation {
    static var displayLabel: String {
        let path = Bundle.main.bundlePath

        if path.hasPrefix("/Applications/") {
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

    static let installHint =
        "Keeping Taptaap in Applications makes Input Monitoring setup more predictable."
}

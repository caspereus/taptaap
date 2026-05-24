import SwiftUI

enum OverlayShowMode: String, CaseIterable, Identifiable {
    case shortcutsOnly
    case allKeystrokes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shortcutsOnly: "Shortcuts Only"
        case .allKeystrokes: "All Keystrokes"
        }
    }
}

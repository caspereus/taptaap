import SwiftUI

enum VisualizerPosition: String, CaseIterable, Identifiable {
    case followCursor
    case topLeft
    case topCenter
    case topRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .followCursor: "Follow Cursor"
        case .topLeft: "Top Left"
        case .topCenter: "Top Center"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomCenter: "Bottom Center"
        case .bottomRight: "Bottom Right"
        }
    }

    var isFollowCursor: Bool { self == .followCursor }

    static var fixedPositions: [VisualizerPosition] {
        allCases.filter { !$0.isFollowCursor }
    }

    static func migrated(from legacyRawValue: String) -> VisualizerPosition {
        switch legacyRawValue {
        case "left": .bottomLeft
        case "center": .bottomCenter
        case "right": .bottomRight
        default:
            VisualizerPosition(rawValue: legacyRawValue) ?? .bottomCenter
        }
    }
}

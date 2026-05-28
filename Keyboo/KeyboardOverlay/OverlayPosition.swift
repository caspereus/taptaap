import SwiftUI

enum OverlayPosition: String, CaseIterable, Identifiable {
    case bottomCenter
    case topCenter
    case center

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bottomCenter: "Bottom Center"
        case .topCenter: "Top Center"
        case .center: "Center"
        }
    }
}

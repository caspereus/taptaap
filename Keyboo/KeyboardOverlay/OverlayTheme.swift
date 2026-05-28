import SwiftUI

enum OverlayTheme: String, CaseIterable, Identifiable {
    case graphite
    case arctic
    case neon
    case sunset
    case forest
    case amethyst

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var containerColor: Color {
        switch self {
        case .graphite:
            return Color.black.opacity(0.62)
        case .arctic:
            return Color(red: 0.22, green: 0.30, blue: 0.40).opacity(0.74)
        case .neon:
            return Color(red: 0.06, green: 0.12, blue: 0.20).opacity(0.8)
        case .sunset:
            return Color(red: 0.26, green: 0.14, blue: 0.14).opacity(0.78)
        case .forest:
            return Color(red: 0.10, green: 0.20, blue: 0.14).opacity(0.8)
        case .amethyst:
            return Color(red: 0.16, green: 0.12, blue: 0.24).opacity(0.8)
        }
    }

    var keycapColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.14)
        case .arctic:
            return Color(red: 0.82, green: 0.91, blue: 1.0).opacity(0.32)
        case .neon:
            return Color(red: 0.18, green: 0.74, blue: 1.0).opacity(0.30)
        case .sunset:
            return Color(red: 1.0, green: 0.66, blue: 0.40).opacity(0.30)
        case .forest:
            return Color(red: 0.62, green: 0.86, blue: 0.52).opacity(0.30)
        case .amethyst:
            return Color(red: 0.80, green: 0.62, blue: 0.96).opacity(0.32)
        }
    }

    var keycapBorderColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.18)
        case .arctic:
            return Color(red: 0.84, green: 0.92, blue: 1.0).opacity(0.55)
        case .neon:
            return Color(red: 0.40, green: 0.92, blue: 1.0).opacity(0.58)
        case .sunset:
            return Color(red: 1.0, green: 0.78, blue: 0.52).opacity(0.58)
        case .forest:
            return Color(red: 0.76, green: 0.94, blue: 0.66).opacity(0.58)
        case .amethyst:
            return Color(red: 0.90, green: 0.78, blue: 1.0).opacity(0.58)
        }
    }

    var textColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.95)
        case .arctic:
            return Color(red: 0.96, green: 0.98, blue: 1.0)
        case .neon:
            return Color(red: 0.90, green: 0.98, blue: 1.0)
        case .sunset:
            return Color(red: 1.0, green: 0.95, blue: 0.90)
        case .forest:
            return Color(red: 0.94, green: 1.0, blue: 0.92)
        case .amethyst:
            return Color(red: 0.97, green: 0.93, blue: 1.0)
        }
    }

    var shadowColor: Color {
        Color.black.opacity(0.35)
    }

    var swatches: [Color] {
        [containerColor.opacity(0.95), keycapColor.opacity(0.95), keycapBorderColor.opacity(0.95)]
    }
}

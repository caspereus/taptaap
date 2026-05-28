import SwiftUI

enum VisualizerTheme: String, CaseIterable, Identifiable {
    case midnight
    case nova
    case neon
    case sakura
    case ocean
    case lavender
    case sunset
    case arctic
    case matcha
    case retro

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var accentColor: Color {
        swatches[0]
    }

    var borderColor: Color {
        swatches[1]
    }

    var keyboardBackground: Color {
        Color(white: 0.10)
    }

    var keyboardFrameColor: Color {
        Color(white: 0.16)
    }

    var keyboardKeyColor: Color {
        Color(white: 0.24)
    }

    var keyboardKeyBorderColor: Color {
        Color(white: 0.32)
    }

    var keyboardActiveKeyColor: Color {
        accentColor.opacity(0.92)
    }

    var keyboardTextColor: Color {
        Color(white: 0.55)
    }

    var keyboardActiveTextColor: Color {
        switch self {
        case .arctic, .matcha, .retro, .sakura, .sunset:
            Color(white: 0.12)
        default:
            Color(white: 0.96)
        }
    }

    var swatches: [Color] {
        switch self {
        case .midnight:
            [Color(red: 0.45, green: 0.55, blue: 0.95), Color(red: 0.25, green: 0.28, blue: 0.38),
             Color(red: 0.18, green: 0.20, blue: 0.28), Color(red: 0.35, green: 0.38, blue: 0.52)]
        case .nova:
            [Color(red: 0.72, green: 0.52, blue: 0.98), Color(red: 0.55, green: 0.35, blue: 0.88),
             Color(red: 0.38, green: 0.28, blue: 0.62), Color(red: 0.88, green: 0.72, blue: 1.0)]
        case .neon:
            [Color(red: 0.20, green: 0.85, blue: 1.0), Color(red: 0.10, green: 0.55, blue: 0.95),
             Color(red: 0.05, green: 0.35, blue: 0.65), Color(red: 0.55, green: 0.95, blue: 1.0)]
        case .sakura:
            [Color(red: 1.0, green: 0.55, blue: 0.72), Color(red: 0.95, green: 0.35, blue: 0.58),
             Color(red: 0.72, green: 0.28, blue: 0.45), Color(red: 1.0, green: 0.78, blue: 0.85)]
        case .ocean:
            [Color(red: 0.25, green: 0.65, blue: 0.95), Color(red: 0.15, green: 0.45, blue: 0.78),
             Color(red: 0.10, green: 0.32, blue: 0.58), Color(red: 0.45, green: 0.82, blue: 0.95)]
        case .lavender:
            [Color(red: 0.72, green: 0.58, blue: 0.95), Color(red: 0.55, green: 0.42, blue: 0.82),
             Color(red: 0.38, green: 0.30, blue: 0.62), Color(red: 0.88, green: 0.78, blue: 1.0)]
        case .sunset:
            [Color(red: 1.0, green: 0.55, blue: 0.28), Color(red: 0.95, green: 0.38, blue: 0.22),
             Color(red: 0.78, green: 0.28, blue: 0.18), Color(red: 1.0, green: 0.72, blue: 0.42)]
        case .arctic:
            [Color(red: 0.82, green: 0.92, blue: 1.0), Color(red: 0.62, green: 0.78, blue: 0.95),
             Color(red: 0.45, green: 0.58, blue: 0.72), Color(red: 0.92, green: 0.96, blue: 1.0)]
        case .matcha:
            [Color(red: 0.55, green: 0.78, blue: 0.42), Color(red: 0.38, green: 0.62, blue: 0.32),
             Color(red: 0.28, green: 0.48, blue: 0.25), Color(red: 0.72, green: 0.88, blue: 0.58)]
        case .retro:
            [Color(red: 0.95, green: 0.72, blue: 0.35), Color(red: 0.82, green: 0.52, blue: 0.28),
             Color(red: 0.62, green: 0.38, blue: 0.22), Color(red: 0.98, green: 0.85, blue: 0.55)]
        }
    }
}

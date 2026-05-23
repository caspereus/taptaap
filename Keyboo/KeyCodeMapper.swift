import AVFoundation
import Carbon
import CoreGraphics

enum KeyCategory {
    case normal
    case space
    case enter
    case backspace
    case modifier
}

enum KeyCodeMapper {
    private static let modifierKeyCodes: Set<CGKeyCode> = [
        CGKeyCode(kVK_Shift),
        CGKeyCode(kVK_RightShift),
        CGKeyCode(kVK_Control),
        CGKeyCode(kVK_RightControl),
        CGKeyCode(kVK_Option),
        CGKeyCode(kVK_RightOption),
        CGKeyCode(kVK_Command),
        CGKeyCode(kVK_RightCommand),
        CGKeyCode(kVK_CapsLock),
        CGKeyCode(kVK_Function)
    ]

    /// Normalized keyboard X position (0 = far left, 1 = far right) for US QWERTY layout.
    private static let panPositionByKeyCode: [CGKeyCode: Float] = [
        CGKeyCode(kVK_ANSI_Grave): 0.0,
        CGKeyCode(kVK_ANSI_1): 0.05,
        CGKeyCode(kVK_ANSI_2): 0.10,
        CGKeyCode(kVK_ANSI_3): 0.15,
        CGKeyCode(kVK_ANSI_4): 0.20,
        CGKeyCode(kVK_ANSI_5): 0.25,
        CGKeyCode(kVK_ANSI_6): 0.30,
        CGKeyCode(kVK_ANSI_7): 0.35,
        CGKeyCode(kVK_ANSI_8): 0.40,
        CGKeyCode(kVK_ANSI_9): 0.45,
        CGKeyCode(kVK_ANSI_0): 0.50,
        CGKeyCode(kVK_ANSI_Minus): 0.55,
        CGKeyCode(kVK_ANSI_Equal): 0.60,
        CGKeyCode(kVK_ANSI_Q): 0.05,
        CGKeyCode(kVK_ANSI_W): 0.10,
        CGKeyCode(kVK_ANSI_E): 0.15,
        CGKeyCode(kVK_ANSI_R): 0.20,
        CGKeyCode(kVK_ANSI_T): 0.25,
        CGKeyCode(kVK_ANSI_Y): 0.30,
        CGKeyCode(kVK_ANSI_U): 0.35,
        CGKeyCode(kVK_ANSI_I): 0.40,
        CGKeyCode(kVK_ANSI_O): 0.45,
        CGKeyCode(kVK_ANSI_P): 0.50,
        CGKeyCode(kVK_ANSI_A): 0.05,
        CGKeyCode(kVK_ANSI_S): 0.10,
        CGKeyCode(kVK_ANSI_D): 0.15,
        CGKeyCode(kVK_ANSI_F): 0.20,
        CGKeyCode(kVK_ANSI_G): 0.25,
        CGKeyCode(kVK_ANSI_H): 0.30,
        CGKeyCode(kVK_ANSI_J): 0.35,
        CGKeyCode(kVK_ANSI_K): 0.40,
        CGKeyCode(kVK_ANSI_L): 0.45,
        CGKeyCode(kVK_ANSI_Z): 0.05,
        CGKeyCode(kVK_ANSI_X): 0.10,
        CGKeyCode(kVK_ANSI_C): 0.15,
        CGKeyCode(kVK_ANSI_V): 0.20,
        CGKeyCode(kVK_ANSI_B): 0.25,
        CGKeyCode(kVK_ANSI_N): 0.30,
        CGKeyCode(kVK_ANSI_M): 0.35
    ]

    /// Keyboard row for Y-axis spatial mapping (0 = top, 1 = bottom).
    private static let rowByKeyCode: [CGKeyCode: Float] = [
        CGKeyCode(kVK_ANSI_Grave): 0.0,
        CGKeyCode(kVK_ANSI_1): 0.0,
        CGKeyCode(kVK_ANSI_2): 0.0,
        CGKeyCode(kVK_ANSI_3): 0.0,
        CGKeyCode(kVK_ANSI_4): 0.0,
        CGKeyCode(kVK_ANSI_5): 0.0,
        CGKeyCode(kVK_ANSI_6): 0.0,
        CGKeyCode(kVK_ANSI_7): 0.0,
        CGKeyCode(kVK_ANSI_8): 0.0,
        CGKeyCode(kVK_ANSI_9): 0.0,
        CGKeyCode(kVK_ANSI_0): 0.0,
        CGKeyCode(kVK_ANSI_Minus): 0.0,
        CGKeyCode(kVK_ANSI_Equal): 0.0,
        CGKeyCode(kVK_ANSI_Q): 0.0,
        CGKeyCode(kVK_ANSI_W): 0.0,
        CGKeyCode(kVK_ANSI_E): 0.0,
        CGKeyCode(kVK_ANSI_R): 0.0,
        CGKeyCode(kVK_ANSI_T): 0.0,
        CGKeyCode(kVK_ANSI_Y): 0.0,
        CGKeyCode(kVK_ANSI_U): 0.0,
        CGKeyCode(kVK_ANSI_I): 0.0,
        CGKeyCode(kVK_ANSI_O): 0.0,
        CGKeyCode(kVK_ANSI_P): 0.0,
        CGKeyCode(kVK_ANSI_A): 0.5,
        CGKeyCode(kVK_ANSI_S): 0.5,
        CGKeyCode(kVK_ANSI_D): 0.5,
        CGKeyCode(kVK_ANSI_F): 0.5,
        CGKeyCode(kVK_ANSI_G): 0.5,
        CGKeyCode(kVK_ANSI_H): 0.5,
        CGKeyCode(kVK_ANSI_J): 0.5,
        CGKeyCode(kVK_ANSI_K): 0.5,
        CGKeyCode(kVK_ANSI_L): 0.5,
        CGKeyCode(kVK_ANSI_Z): 1.0,
        CGKeyCode(kVK_ANSI_X): 1.0,
        CGKeyCode(kVK_ANSI_C): 1.0,
        CGKeyCode(kVK_ANSI_V): 1.0,
        CGKeyCode(kVK_ANSI_B): 1.0,
        CGKeyCode(kVK_ANSI_N): 1.0,
        CGKeyCode(kVK_ANSI_M): 1.0
    ]

    private static let keyboardHalfWidth: Float = 0.15
    private static let keyboardDepth: Float = -0.35
    private static let topRowY: Float = 0.04
    private static let homeRowY: Float = 0.0
    private static let bottomRowY: Float = -0.04

    static func category(for keyCode: CGKeyCode) -> KeyCategory {
        switch keyCode {
        case CGKeyCode(kVK_Space):
            return .space
        case CGKeyCode(kVK_Return), CGKeyCode(kVK_ANSI_KeypadEnter):
            return .enter
        case CGKeyCode(kVK_Delete), CGKeyCode(kVK_ForwardDelete):
            return .backspace
        default:
            if modifierKeyCodes.contains(keyCode) {
                return .modifier
            }
            return .normal
        }
    }

    static func spatialPosition(for keyCode: CGKeyCode) -> AVAudio3DPoint {
        switch category(for: keyCode) {
        case .space:
            return AVAudio3DPoint(x: 0, y: bottomRowY, z: keyboardDepth)
        case .enter:
            return AVAudio3DPoint(x: keyboardHalfWidth * 0.8, y: homeRowY, z: keyboardDepth)
        case .backspace:
            return AVAudio3DPoint(x: -keyboardHalfWidth * 0.8, y: topRowY, z: keyboardDepth)
        case .modifier:
            return AVAudio3DPoint(x: -keyboardHalfWidth, y: bottomRowY, z: keyboardDepth)
        case .normal:
            guard let xPosition = panPositionByKeyCode[keyCode] else {
                return AVAudio3DPoint(x: 0, y: homeRowY, z: keyboardDepth)
            }

            let x = (xPosition - 0.5) * 2.0 * keyboardHalfWidth
            let y = yPosition(forRow: rowByKeyCode[keyCode] ?? 0.5)
            return AVAudio3DPoint(x: x, y: y, z: keyboardDepth)
        }
    }

    private static func yPosition(forRow row: Float) -> Float {
        switch row {
        case 0.0: topRowY
        case 1.0: bottomRowY
        default: homeRowY
        }
    }

    static func countsTowardTypingSpeed(for keyCode: CGKeyCode) -> Bool {
        switch category(for: keyCode) {
        case .normal, .space: true
        default: false
        }
    }
}

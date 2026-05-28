import Carbon
import CoreGraphics

struct KeyboardKey: Identifiable {
    let id: String
    let keyCode: CGKeyCode?
    let widthUnits: CGFloat

    static func key(_ keyCode: CGKeyCode, width: CGFloat = 1) -> KeyboardKey {
        KeyboardKey(id: "key-\(keyCode)", keyCode: keyCode, widthUnits: width)
    }
}

struct KeyboardRow: Identifiable {
    let id: String
    let indentUnits: CGFloat
    let keys: [KeyboardKey]
}

enum KeyboardLayout {
    static let unitWidth: CGFloat = 17
    static let keyHeight: CGFloat = 20
    static let keySpacing: CGFloat = 3
    static let rowSpacing: CGFloat = 4

    /// Compact four-row US ANSI layout — no function or number row, aligned modifier columns.
    static let rows: [KeyboardRow] = [
        KeyboardRow(
            id: "alpha-1",
            indentUnits: 0,
            keys: [
                .key(CGKeyCode(kVK_Tab), width: 1.5),
                .key(CGKeyCode(kVK_ANSI_Q)),
                .key(CGKeyCode(kVK_ANSI_W)),
                .key(CGKeyCode(kVK_ANSI_E)),
                .key(CGKeyCode(kVK_ANSI_R)),
                .key(CGKeyCode(kVK_ANSI_T)),
                .key(CGKeyCode(kVK_ANSI_Y)),
                .key(CGKeyCode(kVK_ANSI_U)),
                .key(CGKeyCode(kVK_ANSI_I)),
                .key(CGKeyCode(kVK_ANSI_O)),
                .key(CGKeyCode(kVK_ANSI_P)),
                .key(CGKeyCode(kVK_ANSI_LeftBracket)),
                .key(CGKeyCode(kVK_ANSI_RightBracket)),
                .key(CGKeyCode(kVK_Delete), width: 1.5)
            ]
        ),
        KeyboardRow(
            id: "alpha-2",
            indentUnits: 0,
            keys: [
                .key(CGKeyCode(kVK_CapsLock), width: 1.75),
                .key(CGKeyCode(kVK_ANSI_A)),
                .key(CGKeyCode(kVK_ANSI_S)),
                .key(CGKeyCode(kVK_ANSI_D)),
                .key(CGKeyCode(kVK_ANSI_F)),
                .key(CGKeyCode(kVK_ANSI_G)),
                .key(CGKeyCode(kVK_ANSI_H)),
                .key(CGKeyCode(kVK_ANSI_J)),
                .key(CGKeyCode(kVK_ANSI_K)),
                .key(CGKeyCode(kVK_ANSI_L)),
                .key(CGKeyCode(kVK_ANSI_Semicolon)),
                .key(CGKeyCode(kVK_ANSI_Quote)),
                .key(CGKeyCode(kVK_Return), width: 2.25)
            ]
        ),
        KeyboardRow(
            id: "alpha-3",
            indentUnits: 0,
            keys: [
                .key(CGKeyCode(kVK_Shift), width: 2.25),
                .key(CGKeyCode(kVK_ANSI_Z)),
                .key(CGKeyCode(kVK_ANSI_X)),
                .key(CGKeyCode(kVK_ANSI_C)),
                .key(CGKeyCode(kVK_ANSI_V)),
                .key(CGKeyCode(kVK_ANSI_B)),
                .key(CGKeyCode(kVK_ANSI_N)),
                .key(CGKeyCode(kVK_ANSI_M)),
                .key(CGKeyCode(kVK_ANSI_Comma)),
                .key(CGKeyCode(kVK_ANSI_Period)),
                .key(CGKeyCode(kVK_ANSI_Slash)),
                .key(CGKeyCode(kVK_RightShift), width: 2.75)
            ]
        ),
        KeyboardRow(
            id: "modifiers",
            indentUnits: 0,
            keys: [
                .key(CGKeyCode(kVK_Control), width: 1.1),
                .key(CGKeyCode(kVK_Option), width: 1.1),
                .key(CGKeyCode(kVK_Command), width: 1.1),
                .key(CGKeyCode(kVK_Space), width: 9.6),
                .key(CGKeyCode(kVK_RightCommand), width: 1.1),
                .key(CGKeyCode(kVK_RightOption), width: 1.1)
            ]
        )
    ]

    static var contentSize: CGSize {
        let maxRowWidth = rows.map { rowWidth(for: $0) }.max() ?? 0
        let rowCount = CGFloat(rows.count)
        let height = rowCount * keyHeight + max(0, rowCount - 1) * rowSpacing
        return CGSize(width: maxRowWidth, height: height)
    }

    static func rowWidth(for row: KeyboardRow) -> CGFloat {
        let indent = row.indentUnits * (unitWidth + keySpacing)
        let keysWidth = row.keys.reduce(0) { $0 + $1.widthUnits * unitWidth }
        let spacingWidth = max(0, CGFloat(row.keys.count - 1)) * keySpacing
        return indent + keysWidth + spacingWidth
    }
}

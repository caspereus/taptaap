import AppKit
import Carbon

enum KeyFormatter {
    private static let modifierKeyCodes: Set<UInt16> = [
        UInt16(kVK_Shift),
        UInt16(kVK_RightShift),
        UInt16(kVK_Control),
        UInt16(kVK_RightControl),
        UInt16(kVK_Option),
        UInt16(kVK_RightOption),
        UInt16(kVK_Command),
        UInt16(kVK_RightCommand),
        UInt16(kVK_CapsLock),
        UInt16(kVK_Function)
    ]

    private static let letterLabels: [UInt16: String] = [
        UInt16(kVK_ANSI_A): "A", UInt16(kVK_ANSI_B): "B", UInt16(kVK_ANSI_C): "C",
        UInt16(kVK_ANSI_D): "D", UInt16(kVK_ANSI_E): "E", UInt16(kVK_ANSI_F): "F",
        UInt16(kVK_ANSI_G): "G", UInt16(kVK_ANSI_H): "H", UInt16(kVK_ANSI_I): "I",
        UInt16(kVK_ANSI_J): "J", UInt16(kVK_ANSI_K): "K", UInt16(kVK_ANSI_L): "L",
        UInt16(kVK_ANSI_M): "M", UInt16(kVK_ANSI_N): "N", UInt16(kVK_ANSI_O): "O",
        UInt16(kVK_ANSI_P): "P", UInt16(kVK_ANSI_Q): "Q", UInt16(kVK_ANSI_R): "R",
        UInt16(kVK_ANSI_S): "S", UInt16(kVK_ANSI_T): "T", UInt16(kVK_ANSI_U): "U",
        UInt16(kVK_ANSI_V): "V", UInt16(kVK_ANSI_W): "W", UInt16(kVK_ANSI_X): "X",
        UInt16(kVK_ANSI_Y): "Y", UInt16(kVK_ANSI_Z): "Z"
    ]

    private static let digitLabels: [UInt16: String] = [
        UInt16(kVK_ANSI_0): "0", UInt16(kVK_ANSI_1): "1", UInt16(kVK_ANSI_2): "2",
        UInt16(kVK_ANSI_3): "3", UInt16(kVK_ANSI_4): "4", UInt16(kVK_ANSI_5): "5",
        UInt16(kVK_ANSI_6): "6", UInt16(kVK_ANSI_7): "7", UInt16(kVK_ANSI_8): "8",
        UInt16(kVK_ANSI_9): "9"
    ]

    private static let shiftedDigitLabels: [UInt16: String] = [
        UInt16(kVK_ANSI_0): ")", UInt16(kVK_ANSI_1): "!", UInt16(kVK_ANSI_2): "@",
        UInt16(kVK_ANSI_3): "#", UInt16(kVK_ANSI_4): "$", UInt16(kVK_ANSI_5): "%",
        UInt16(kVK_ANSI_6): "^", UInt16(kVK_ANSI_7): "&", UInt16(kVK_ANSI_8): "*",
        UInt16(kVK_ANSI_9): "("
    ]

    /// Returns ordered keycap labels for display (modifiers first, then the key).
    static func keycapLabels(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> [String] {
        guard !modifierKeyCodes.contains(keyCode) else { return [] }

        var labels: [String] = []
        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)

        if flags.contains(.control) { labels.append("⌃") }
        if flags.contains(.option) { labels.append("⌥") }
        if flags.contains(.shift) { labels.append("⇧") }
        if flags.contains(.command) { labels.append("⌘") }
        if flags.contains(.capsLock) { labels.append("⇪") }

        if let keyLabel = keyLabel(for: keyCode, shiftHeld: flags.contains(.shift)) {
            labels.append(keyLabel)
        }

        return labels
    }

    static func hasActionModifiers(_ modifierFlags: NSEvent.ModifierFlags) -> Bool {
        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.contains(.command)
            || flags.contains(.shift)
            || flags.contains(.option)
            || flags.contains(.control)
    }

    static func isNormalTypingKey(keyCode: UInt16) -> Bool {
        letterLabels[keyCode] != nil || digitLabels[keyCode] != nil
    }

    static func isSpecialKey(keyCode: UInt16) -> Bool {
        specialKeyLabel(for: keyCode) != nil
    }

    /// Maps a key event to the character it would produce on a US QWERTY layout.
    static func typedCharacter(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> String? {
        guard !modifierKeyCodes.contains(keyCode) else { return nil }

        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) || flags.contains(.control) || flags.contains(.option) {
            return nil
        }

        let shiftHeld = flags.contains(.shift) != flags.contains(.capsLock)

        switch Int(keyCode) {
        case kVK_Space: return " "
        case kVK_Return, kVK_ANSI_KeypadEnter: return "\n"
        case kVK_Delete, kVK_ForwardDelete: return nil
        case kVK_Tab: return "\t"
        default:
            return keyLabel(for: keyCode, shiftHeld: shiftHeld)
        }
    }

    private static func keyLabel(for keyCode: UInt16, shiftHeld: Bool) -> String? {
        if let special = specialKeyLabel(for: keyCode) {
            return special
        }
        if shiftHeld, let shifted = shiftedDigitLabels[keyCode] {
            return shifted
        }
        if let digit = digitLabels[keyCode] {
            return digit
        }
        if let letter = letterLabels[keyCode] {
            return shiftHeld ? letter : letter.lowercased()
        }
        if let punctuation = punctuationLabel(for: keyCode, shiftHeld: shiftHeld) {
            return punctuation
        }
        return nil
    }

    private static func specialKeyLabel(for keyCode: UInt16) -> String? {
        switch Int(keyCode) {
        case kVK_Return, kVK_ANSI_KeypadEnter: "Return"
        case kVK_Tab: "Tab"
        case kVK_Space: "Space"
        case kVK_Delete: "Delete"
        case kVK_Escape: "Esc"
        case kVK_LeftArrow: "←"
        case kVK_RightArrow: "→"
        case kVK_UpArrow: "↑"
        case kVK_DownArrow: "↓"
        case kVK_ForwardDelete: "Delete"
        case kVK_Home: "Home"
        case kVK_End: "End"
        case kVK_PageUp: "PgUp"
        case kVK_PageDown: "PgDn"
        default: nil
        }
    }

    private static func punctuationLabel(for keyCode: UInt16, shiftHeld: Bool) -> String? {
        switch Int(keyCode) {
        case kVK_ANSI_Minus: shiftHeld ? "_" : "-"
        case kVK_ANSI_Equal: shiftHeld ? "+" : "="
        case kVK_ANSI_LeftBracket: shiftHeld ? "{" : "["
        case kVK_ANSI_RightBracket: shiftHeld ? "}" : "]"
        case kVK_ANSI_Backslash: shiftHeld ? "|" : "\\"
        case kVK_ANSI_Semicolon: shiftHeld ? ":" : ";"
        case kVK_ANSI_Quote: shiftHeld ? "\"" : "'"
        case kVK_ANSI_Comma: shiftHeld ? "<" : ","
        case kVK_ANSI_Period: shiftHeld ? ">" : "."
        case kVK_ANSI_Slash: shiftHeld ? "?" : "/"
        case kVK_ANSI_Grave: shiftHeld ? "~" : "`"
        default: nil
        }
    }
}

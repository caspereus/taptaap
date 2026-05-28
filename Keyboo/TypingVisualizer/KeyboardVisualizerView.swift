import Carbon
import SwiftUI

struct KeyboardVisualizerView: View {
    let pressedKeyCodes: Set<CGKeyCode>
    let theme: VisualizerTheme

    private let keyCornerRadius: CGFloat = 5
    private let frameCornerRadius: CGFloat = 14

    var body: some View {
        keyboardBody
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: frameCornerRadius + 4, style: .continuous)
                    .fill(theme.keyboardBackground)
                    .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
            }
    }

    private var keyboardBody: some View {
        VStack(alignment: .leading, spacing: KeyboardLayout.rowSpacing) {
            ForEach(KeyboardLayout.rows) { row in
                keyboardRow(row)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: frameCornerRadius, style: .continuous)
                .fill(theme.keyboardFrameColor)
        }
    }

    private func keyboardRow(_ row: KeyboardRow) -> some View {
        HStack(spacing: KeyboardLayout.keySpacing) {
            if row.indentUnits > 0 {
                Spacer(minLength: 0)
                    .frame(width: row.indentUnits * (KeyboardLayout.unitWidth + KeyboardLayout.keySpacing))
            }

            ForEach(row.keys) { key in
                keyView(for: key)
            }
        }
    }

    @ViewBuilder
    private func keyView(for key: KeyboardKey) -> some View {
        let width = key.widthUnits * KeyboardLayout.unitWidth

        if let keyCode = key.keyCode {
            let isPressed = isKeyPressed(keyCode)

            ZStack {
                RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                    .fill(isPressed ? theme.keyboardActiveKeyColor : theme.keyboardKeyColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                            .strokeBorder(
                                isPressed ? theme.accentColor.opacity(0.55) : theme.keyboardKeyBorderColor,
                                lineWidth: isPressed ? 1 : 0.5
                            )
                    }

                if let label = KeyFormatter.visualizerLabel(for: UInt16(keyCode)) {
                    Text(label)
                        .font(.system(size: labelFontSize(for: label, keyWidth: width), weight: .medium, design: .rounded))
                        .foregroundStyle(isPressed ? theme.keyboardActiveTextColor : theme.keyboardTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else if keyCode == CGKeyCode(kVK_Space) {
                    Capsule()
                        .fill(theme.keyboardTextColor.opacity(isPressed ? 0.85 : 0.35))
                        .frame(width: min(width * 0.55, 44), height: 2)
                }
            }
            .frame(width: width, height: KeyboardLayout.keyHeight)
            .animation(.easeOut(duration: 0.08), value: isPressed)
        } else {
            Color.clear
                .frame(width: width, height: KeyboardLayout.keyHeight)
        }
    }

    private func isKeyPressed(_ keyCode: CGKeyCode) -> Bool {
        pressedKeyCodes.contains(keyCode)
            || (keyCode == CGKeyCode(kVK_Delete) && pressedKeyCodes.contains(CGKeyCode(kVK_ForwardDelete)))
    }

    private func labelFontSize(for label: String, keyWidth: CGFloat) -> CGFloat {
        if label.count <= 1 {
            return min(11, keyWidth * 0.52)
        }
        return min(8.5, keyWidth * 0.28)
    }
}

#Preview {
    KeyboardVisualizerView(
        pressedKeyCodes: [
            CGKeyCode(kVK_Tab),
            CGKeyCode(kVK_CapsLock),
            CGKeyCode(kVK_Delete),
            CGKeyCode(kVK_ANSI_M),
            CGKeyCode(kVK_Shift),
            CGKeyCode(kVK_Space)
        ],
        theme: .midnight
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

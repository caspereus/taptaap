import Carbon
import SwiftUI

struct KeyboardVisualizerView: View {
    let pressedKeyCodes: Set<CGKeyCode>
    let recentText: String
    let theme: VisualizerTheme

    private let keyCornerRadius: CGFloat = 4
    private let frameCornerRadius: CGFloat = 14

    var body: some View {
        VStack(spacing: 10) {
            recentTextView

            keyboardBody
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: frameCornerRadius + 4, style: .continuous)
                .fill(theme.keyboardBackground)
                .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        }
    }

    private var recentTextView: some View {
        Text(displayText)
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundStyle(theme.keyboardTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .frame(height: 14)
    }

    private var displayText: String {
        let trimmed = recentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return " " }
        return trimmed
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
            let isPressed = pressedKeyCodes.contains(keyCode)

            RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                .fill(isPressed ? theme.keyboardActiveKeyColor : theme.keyboardKeyColor)
                .frame(width: width, height: KeyboardLayout.unitWidth)
                .animation(.easeOut(duration: 0.08), value: isPressed)
        } else {
            Color.clear
                .frame(width: width, height: KeyboardLayout.unitWidth)
        }
    }
}

#Preview {
    KeyboardVisualizerView(
        pressedKeyCodes: [
            CGKeyCode(kVK_ANSI_M),
            CGKeyCode(kVK_ANSI_O),
            CGKeyCode(kVK_ANSI_V),
            CGKeyCode(kVK_ANSI_E),
            CGKeyCode(kVK_Space)
        ],
        recentText: "move set write but",
        theme: .midnight
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

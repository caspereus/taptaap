import SwiftUI

struct KeyboardOverlayView: View {
    let keycaps: [String]
    var theme: OverlayTheme = .graphite
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(keycaps.enumerated()), id: \.offset) { _, label in
                KeycapView(label: label, theme: theme)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.containerColor)
                .shadow(color: theme.shadowColor, radius: 18, y: 6)
        }
        .scaleEffect(isVisible ? 1 : 0.92)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                isVisible = true
            }
        }
        .onChange(of: keycaps) { _, _ in
            isVisible = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                isVisible = true
            }
        }
    }
}

private struct KeycapView: View {
    let label: String
    let theme: OverlayTheme

    private var isCompactLabel: Bool {
        label.count <= 1
    }

    var body: some View {
        Text(label)
            .font(.system(size: isCompactLabel ? 22 : 18, weight: .semibold, design: .rounded))
            .foregroundStyle(theme.textColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, isCompactLabel ? 14 : 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.keycapColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(theme.keycapBorderColor, lineWidth: 0.75)
                    }
            }
            .frame(minWidth: isCompactLabel ? 48 : nil)
    }
}

#Preview("Shortcut") {
    KeyboardOverlayView(keycaps: ["⌘", "⇧", "P"], theme: .neon)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}

#Preview("Special keys") {
    KeyboardOverlayView(keycaps: ["Space"], theme: .sunset)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}

#Preview("Long shortcut") {
    KeyboardOverlayView(keycaps: ["⌃", "⌥", "⇧", "⌘", "Delete"], theme: .forest)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}

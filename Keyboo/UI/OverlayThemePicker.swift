import SwiftUI

struct OverlayThemePicker: View {
    @Binding var selection: OverlayTheme
    var isEnabled: Bool = true

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(OverlayTheme.allCases) { theme in
                themeButton(theme)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private func themeButton(_ theme: OverlayTheme) -> some View {
        let isSelected = selection == theme

        return Button {
            selection = theme
        } label: {
            VStack(spacing: 6) {
                OverlayThemeSwatch(theme: theme, isSelected: isSelected)
                    .frame(height: 32)

                Text(theme.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct OverlayThemeSwatch: View {
    let theme: OverlayTheme
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .overlay {
                HStack(spacing: 4) {
                    ForEach(Array(theme.swatches.enumerated()), id: \.offset) { _, color in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(color)
                    }
                }
                .padding(6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.95) : theme.keycapBorderColor.opacity(0.75),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            }
            .shadow(color: isSelected ? theme.keycapBorderColor.opacity(0.35) : .clear, radius: 4)
    }
}

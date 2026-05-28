import SwiftUI

struct VisualizerThemePicker: View {
    @Binding var selection: VisualizerTheme
    var isEnabled: Bool = true

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(VisualizerTheme.allCases) { theme in
                themeButton(theme)
            }
        }
        .opacity(isEnabled ? 1 : 0.45)
        .allowsHitTesting(isEnabled)
    }

    private func themeButton(_ theme: VisualizerTheme) -> some View {
        let isSelected = selection == theme

        return Button {
            selection = theme
        } label: {
            VStack(spacing: 6) {
                VisualizerThemeSwatch(theme: theme, isSelected: isSelected)
                    .frame(height: 36)

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

private struct VisualizerThemeSwatch: View {
    let theme: VisualizerTheme
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .overlay {
                HStack(spacing: 3) {
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
                        isSelected ? Color.white.opacity(0.95) : theme.borderColor.opacity(0.75),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            }
            .shadow(color: isSelected ? theme.borderColor.opacity(0.35) : .clear, radius: 4)
    }
}

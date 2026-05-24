import SwiftUI

struct OverlayPositionPicker: View {
    @Binding var selection: OverlayPosition
    var isEnabled: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            ForEach(OverlayPosition.allCases) { position in
                positionButton(position)
            }
        }
        .opacity(isEnabled ? 1 : 0.45)
        .allowsHitTesting(isEnabled)
    }

    private func positionButton(_ position: OverlayPosition) -> some View {
        let isSelected = selection == position

        return Button {
            selection = position
        } label: {
            VStack(spacing: 6) {
                OverlayPositionIcon(position: position)
                    .frame(width: 28, height: 18)

                Text(position.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.06 : 0.03))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct OverlayPositionIcon: View {
    let position: OverlayPosition

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let dotSize: CGFloat = 4

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.55), lineWidth: 1)
                .overlay {
                    Circle()
                        .fill(Color.secondary.opacity(0.75))
                        .frame(width: dotSize, height: dotSize)
                        .position(dotPosition(in: size))
                }
        }
    }

    private func dotPosition(in size: CGSize) -> CGPoint {
        let inset: CGFloat = 5
        switch position {
        case .topCenter:
            return CGPoint(x: size.width / 2, y: inset)
        case .bottomCenter:
            return CGPoint(x: size.width / 2, y: size.height - inset)
        case .center:
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
}

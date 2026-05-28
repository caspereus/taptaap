import SwiftUI

struct TypingSpeedHUD: View {
    let wpm: Int
    let kpm: Int
    let accentColor: Color
    var animateValues: Bool = true

    var body: some View {
        GlassCapsuleSurface {
            HStack(spacing: 24) {
                SpeedMetricView(
                    value: wpm,
                    label: "WPM",
                    color: accentColor,
                    animate: animateValues
                )
                SpeedMetricView(
                    value: kpm,
                    label: "KPM",
                    color: accentColor,
                    animate: animateValues
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

struct SpeedMetricView: View {
    let value: Int
    let label: String
    let color: Color
    var animate: Bool = true

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .modifier(AnimatedNumericTextModifier(isEnabled: animate, value: value))

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 64)
    }
}

private struct AnimatedNumericTextModifier: ViewModifier {
    let isEnabled: Bool
    let value: Int

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: value)
        } else {
            content
        }
    }
}

#Preview {
    TypingSpeedHUD(wpm: 72, kpm: 360, accentColor: .orange)
        .padding()
        .background(Color.gray.opacity(0.2))
}

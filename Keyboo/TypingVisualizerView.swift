import SwiftUI

struct TypingVisualizerView: View {
    @ObservedObject var visualizer: TypingVisualizer

    var body: some View {
        HStack(spacing: 24) {
            SpeedMetricView(
                value: visualizer.currentWPM,
                label: "WPM",
                color: visualizer.accentColor
            )
            SpeedMetricView(
                value: visualizer.currentKPM,
                label: "KPM",
                color: visualizer.accentColor
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.black.opacity(0.28))
        }
        .frame(width: TypingVisualizer.panelSize.width, height: TypingVisualizer.panelSize.height)
    }
}

private struct SpeedMetricView: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: value)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 64)
    }
}

#Preview {
    TypingVisualizerView(visualizer: TypingVisualizer.shared)
        .padding()
        .background(Color.gray.opacity(0.2))
}

import SwiftUI

struct TypingVisualizerView: View {
    @ObservedObject var visualizer: TypingVisualizer

    var body: some View {
        KeyboardVisualizerView(
            pressedKeyCodes: visualizer.pressedKeyCodes,
            theme: visualizer.theme
        )
        .frame(width: TypingVisualizer.panelSize.width, height: TypingVisualizer.panelSize.height)
    }
}

#Preview {
    TypingVisualizerView(visualizer: TypingVisualizer.shared)
        .padding()
        .background(Color.gray.opacity(0.2))
}

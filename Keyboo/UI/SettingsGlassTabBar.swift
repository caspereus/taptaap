import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case sound
    case visualizer
    case overlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .sound: "Sound"
        case .visualizer: "Visualizer"
        case .overlay: "Overlay"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .sound: "speaker.wave.2"
        case .visualizer: "gauge.with.dots.needle.67percent"
        case .overlay: "rectangle.on.rectangle"
        }
    }
}

struct SettingsGlassTabBar: View {
    @Binding var selection: SettingsTab
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(SettingsTab.allCases.enumerated()), id: \.element.id) { index, tab in
                if index > 0 {
                    tabDivider
                }
                tabButton(for: tab)
            }
        }
        .padding(3)
        .glassEffect(.regular, in: Capsule())
    }

    private var tabDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 1)
    }

    private func tabButton(for tab: SettingsTab) -> some View {
        let isSelected = selection == tab

        return Button {
            withAnimation(.snappy(duration: 0.28)) {
                selection = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        .background {
            if isSelected {
                Capsule()
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .matchedGeometryEffect(id: "tabSelection", in: selectionNamespace)
            }
        }
    }
}

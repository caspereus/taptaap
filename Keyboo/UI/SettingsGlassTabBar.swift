import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case sound
    case visualizer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .sound: "Sound"
        case .visualizer: "Visualizer"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .sound: "speaker.wave.2"
        case .visualizer: "gauge.with.dots.needle.67percent"
        }
    }
}

struct SettingsGlassTabBar: View {
    @Binding var selection: SettingsTab
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(5)
        .glassEffect(.regular, in: Capsule())
    }

    private func tabButton(for tab: SettingsTab) -> some View {
        let isSelected = selection == tab

        return Button {
            withAnimation(.snappy(duration: 0.28)) {
                selection = tab
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(tab.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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

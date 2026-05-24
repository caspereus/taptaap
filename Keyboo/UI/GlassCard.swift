import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(KeybooGlass.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(KeybooGlass.cardStyle, in: KeybooGlass.cardShape)
    }
}

import SwiftUI

struct GlassCapsuleSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .glassEffect(.regular, in: Capsule())
    }
}

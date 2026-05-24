import SwiftUI

enum KeybooGlass {
    static let cardCornerRadius: CGFloat = 10
    static let cardPadding: CGFloat = 14
    static let containerSpacing: CGFloat = 20
    static let cardStyle: Glass = .regular

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }
}

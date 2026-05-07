import SwiftUI

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum Radius {
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 18
    static let lg:  CGFloat = 28
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: .black.opacity(0.04), radius: 30, y: 8)
    }

    func minTapTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}

import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

struct SoftCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(.white.opacity(0.8), lineWidth: 0.5)
            )
    }
}

import SwiftUI

struct Tag: View {
    let text: String
    var background: Color = .lavenderSoft
    var foreground: Color = .lavenderDeep

    var body: some View {
        Text(String(localized: String.LocalizationValue(text)))
            .font(.pretendard(11, .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(background)
            .clipShape(Capsule())
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.pretendard(10, .semibold))
            .foregroundStyle(Color(hex: 0x7E6228))
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Color.cream)
            .clipShape(Capsule())
    }
}

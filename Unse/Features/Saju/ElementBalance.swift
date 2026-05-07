import SwiftUI

struct ElementBalance: View {
    let distribution: [Element: Int]

    private var maxCount: Int { distribution.values.max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Element.allCases, id: \.self) { el in
                let count = distribution[el] ?? 0
                elementBar(el, count: count)
            }
        }
    }

    private func elementBar(_ el: Element, count: Int) -> some View {
        let colors = el.colors
        let height: CGFloat = 64 + CGFloat(count) * 6

        return VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(count == 0 ? Color(hex: 0xF4F2EC) : colors.background)
                    .opacity(count == 0 ? 0.4 : 0.85)
                    .frame(height: height)
                if count > 0 {
                    Text("\(count)")
                        .font(.pretendard(14, .bold))
                        .foregroundStyle(colors.text)
                        .padding(.bottom, 6)
                }
            }
            Text(el.rawValue)
                .font(.serifKR(13, .medium))
                .foregroundStyle(.ink1)
            Text(el.korean)
                .font(.pretendard(10))
                .foregroundStyle(.ink3)
        }
        .frame(maxWidth: .infinity)
    }
}

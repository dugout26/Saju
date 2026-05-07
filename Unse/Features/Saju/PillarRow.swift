import SwiftUI

// MARK: - PillarRow

struct PillarRow: View {
    let pillars: [(label: String, pillar: Pillar)]
    var showHan: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            ForEach(pillars, id: \.label) { item in
                PillarColumn(label: item.label, pillar: item.pillar, showHan: showHan)
            }
        }
    }
}

// MARK: - PillarColumn

struct PillarColumn: View {
    let label: String
    let pillar: Pillar
    var showHan: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.pretendard(10, .semibold))
                .foregroundStyle(.ink3)
                .tracking(0.5)
            PillarCell(char: pillar.stem.character, element: pillar.stem.element, subtext: showHan ? pillar.stem.korean : nil)
            PillarCell(char: pillar.branch.character, element: pillar.branch.element, subtext: showHan ? pillar.branch.korean : nil)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PillarCell

struct PillarCell: View {
    let char: String
    let element: Element
    var subtext: String? = nil

    var body: some View {
        let colors = element.colors
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.background)
            VStack(spacing: 2) {
                Text(char)
                    .font(.serifKR(28, .medium))
                    .foregroundStyle(colors.text)
                if let sub = subtext {
                    Text(sub)
                        .font(.pretendard(9, .medium))
                        .foregroundStyle(colors.text.opacity(0.65))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(char) \(subtext ?? "")")
    }
}

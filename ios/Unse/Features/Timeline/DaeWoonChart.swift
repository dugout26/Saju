import SwiftUI
import Charts

struct DaeWoonChart: View {
    let daeWoon: [DaeWoon]
    let currentAge: Int

    private var currentDecade: DaeWoon? {
        daeWoon.last { $0.startAge <= currentAge }
    }

    var body: some View {
        Chart {
            ForEach(Array(daeWoon.enumerated()), id: \.offset) { idx, dw in
                let isCurrent = dw.id == currentDecade?.id
                BarMark(
                    x: .value("나이", "\(dw.startAge)세"),
                    y: .value("기운", fortuneScore(for: dw, index: idx))
                )
                .foregroundStyle(isCurrent ? Color.lavenderDeep : Color.lavender.opacity(0.6))
                .cornerRadius(6)
                .annotation(position: .top) {
                    VStack(spacing: 1) {
                        Text(dw.pillar.stem.character)
                            .font(.serifKR(11, .semibold))
                            .foregroundStyle(isCurrent ? Color.lavenderDeep : Color.ink3)
                        Text(dw.pillar.branch.character)
                            .font(.serifKR(11, .semibold))
                            .foregroundStyle(isCurrent ? Color.lavenderDeep : Color.ink3)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.pretendard(10))
                            .foregroundStyle(Color.ink3)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 160)
    }

    private func fortuneScore(for dw: DaeWoon, index: Int) -> Double {
        let stemScore: Double = switch dw.pillar.stem.element {
        case .wood:  0.75
        case .fire:  0.90
        case .earth: 0.65
        case .metal: 0.70
        case .water: 0.80
        }
        let wave = sin(Double(index) * 0.9) * 0.15
        return max(0.4, min(1.0, stemScore + wave))
    }
}

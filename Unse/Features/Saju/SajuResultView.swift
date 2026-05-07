import SwiftUI

struct SajuResultView: View {
    let saju: SajuComputed
    let daeWoon: [DaeWoon]
    let nickname: String

    @Environment(\.dismiss) private var dismiss
    @State private var showDaily = false
    @State private var showHan = true
    @State private var stage1Text: String?
    @State private var stage2Text: String?

    private var pillarData: [(label: String, pillar: Pillar)] {
        [("시주", saju.hour), ("일주", saju.day), ("월주", saju.month), ("년주", saju.year)]
            .compactMap { label, p in p.map { (label, $0) } }
            .filter { $0.label != "시주" || saju.hour != nil }
        // Always show year/month/day; hour only if available
        + (saju.hour == nil ? [("년주", saju.year), ("월주", saju.month), ("일주", saju.day)] : [])
    }

    private var orderedPillars: [(label: String, pillar: Pillar)] {
        var result: [(String, Pillar)] = []
        if let h = saju.hour { result.append(("시주", h)) }
        result.append(("일주", saju.day))
        result.append(("월주", saju.month))
        result.append(("년주", saju.year))
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerSection
                pillarsCard
                elementCard
                tendencyCard
                ctaButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.ink1)
                }
                .minTapTarget()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Share sheet
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.ink1)
                }
                .minTapTarget()
            }
        }
        .navigationDestination(isPresented: $showDaily) {
            DailyFortuneView(user: nil)
        }
        .task { await loadReadings() }
    }

    private func loadReadings() async {
        async let s1 = try? await APIClient.shared.fetchSajuReading(stage: 1, saju: saju, nickname: nickname)
        async let s2 = try? await APIClient.shared.fetchSajuReading(stage: 2, saju: saju, nickname: nickname)
        let (r1, r2) = await (s1, s2)
        if let r1 { stage1Text = r1 }
        if let r2 { stage2Text = r2 }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Tag(text: "1단계 · 기본 풀이")
            Text("\(nickname)님의 사주는\n")
                .font(.serifKR(26, .semibold))
                .foregroundStyle(.ink1)
            + Text("\(saju.dayMaster.character)\(saju.dayMaster.korean.first.map(String.init) ?? "")(\(saju.dayMaster.korean)) 일간")
                .font(.serifKR(26, .semibold))
                .foregroundStyle(.lavenderDeep)

            Text("사주 기반 분석")
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var pillarsCard: some View {
        Card {
            VStack(spacing: 16) {
                PillarRow(pillars: orderedPillars, showHan: showHan)

                // 일간 highlight (Phase B fetchSajuReading stage 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text("일간 (나의 본성)")
                        .font(.pretendard(11, .semibold))
                        .foregroundStyle(Color(hex: 0x7E6228))
                    Text(stage1Text ?? "분석 중...")
                        .font(.serifKR(15, .medium))
                        .foregroundStyle(.ink1)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: 0xF1E4C7))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var elementCard: some View {
        Card {
            VStack(spacing: 16) {
                HStack {
                    Text("오행 균형")
                        .font(.pretendard(15, .semibold))
                        .foregroundStyle(.ink1)
                    Spacer()
                    Text("\(saju.dominantElement.rawValue) 기운이 강함")
                        .font(.pretendard(12))
                        .foregroundStyle(.ink3)
                }
                ElementBalance(distribution: saju.fiveElements)
            }
        }
    }

    private var tendencyCard: some View {
        // Phase B fetchSajuReading stage 2
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("성향 한 줄")
                    .font(.pretendard(15, .semibold))
                    .foregroundStyle(.ink1)
                Text(stage2Text ?? "분석 중...")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink2)
                    .lineSpacing(5)
                PillButton(title: "2단계 풀이 보기 →") {}
            }
        }
    }

    private var ctaButton: some View {
        PrimaryButton(title: "오늘의 운세 보기") {
            showDaily = true
        }
        .padding(.top, 4)
    }
}

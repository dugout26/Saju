import SwiftUI

struct SajuResultView: View {
    let saju: SajuComputed
    let daeWoon: [DaeWoon]
    let nickname: String

    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var sub
    @State private var vm = SajuResultViewModel()
    @State private var showDaily = false
    @State private var showHan = true
    @State private var showPaywall = false
    @State private var chatPrompt: String?

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
                lifeFortuneCard
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
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(sub)
        }
        .sheet(item: Binding(
            get: { chatPrompt.map { ChatPromptItem(text: $0) } },
            set: { chatPrompt = $0?.text }
        )) { item in
            ChatView(user: nil, nickname: nickname, initialQuestion: item.text)
                .environment(sub)
        }
        .task { await vm.loadReadings(saju: saju, nickname: nickname) }
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
                    Text(.init(vm.stage1Text ?? "분석 중..."))
                        .font(.serifKR(15, .medium))
                        .foregroundStyle(.ink1)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: 0xF1E4C7))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                askMoreButton(question: "제 일간이 \(saju.dayMaster.character)\(saju.dayMaster.korean)인데, 이 일간이 일상에서 어떻게 드러나는지 더 자세히 알려주세요.")
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
                Text(.init(vm.stage2Text ?? "분석 중..."))
                    .font(.pretendard(14))
                    .foregroundStyle(.ink2)
                    .lineSpacing(5)
                askMoreButton(question: "제 성격에서 강점과 약점, 사람들과의 관계에서 드러나는 모습을 더 구체적으로 알려주세요.")
            }
        }
    }

    private func askMoreButton(question: String) -> some View {
        Button {
            chatPrompt = question
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                Text("이 부분 AI에 더 물어보기")
                    .font(.pretendard(12, .semibold))
            }
            .foregroundStyle(.lavenderDeep)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.lavenderSoft)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var lifeFortuneCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("평생운 종합 풀이")
                        .font(.pretendard(15, .semibold))
                        .foregroundStyle(.ink1)
                    Spacer()
                    if !sub.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.lavenderDeep)
                    }
                }
                Text("일생의 큰 흐름과 시기별 조언을\n자평명리 정통 방식으로 자세히 풀어드립니다.")
                    .font(.pretendard(13))
                    .foregroundStyle(.ink2)
                    .lineSpacing(4)
                PillButton(title: sub.isPremium ? "5단계 풀이 보기 →" : "PRO로 잠금 해제 →") {
                    if !sub.isPremium { showPaywall = true }
                    // TODO(Phase D): PRO일 때 stage 5 fetch + 별도 화면
                }
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

private struct ChatPromptItem: Identifiable {
    let text: String
    var id: String { text }
}

import SwiftUI
import Charts

struct TimelineView: View {
    var user: UserProfile?

    @Environment(SubscriptionManager.self) private var sub
    @State private var daeWoon: [DaeWoon] = []
    @State private var selectedDaeWoon: DaeWoon?
    @State private var showPaywall = false

    private var currentAge: Int {
        guard let profile = user?.sajuProfile else { return 30 }
        return Calendar.current.component(.year, from: Date()) - profile.birthYear
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                ZStack(alignment: .center) {
                    VStack(spacing: 16) {
                        chartSection
                        decadeList
                    }
                    .blur(radius: sub.isPremium ? 0 : 10)
                    .allowsHitTesting(sub.isPremium)

                    if !sub.isPremium {
                        proLockCard
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("평생 흐름")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadDaeWoon() }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(sub)
        }
    }

    private var proLockCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 26))
                .foregroundStyle(.lavenderDeep)
            Text("평생운 그래프는 PRO 전용")
                .font(.serifKR(17, .semibold))
                .foregroundStyle(.ink1)
            Text("10년 단위 대운 흐름과\n시기별 조언을 자세히 보세요")
                .font(.pretendard(12))
                .foregroundStyle(.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            PrimaryButton(title: "PRO로 자세히 보기", color: .lavenderDeep) {
                showPaywall = true
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 6)
        .padding(.horizontal, 8)
    }

    // MARK: - Sub-views

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Tag(text: "대운 · 10년 주기")
            Text("큰 흐름으로 보는\n인생의 지도")
                .font(.serifKR(26, .semibold))
                .foregroundStyle(.ink1)
                .lineSpacing(4)
            Text("대운은 10년 단위로 찾아오는 큰 기운의 흐름입니다")
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var chartSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("대운 그래프")
                    .font(.pretendard(15, .semibold))
                    .foregroundStyle(.ink1)

                if daeWoon.isEmpty {
                    placeholderChart
                } else {
                    DaeWoonChart(daeWoon: daeWoon, currentAge: currentAge)
                }

                HStack(spacing: 16) {
                    legendItem(color: .lavenderDeep, label: "현재 대운")
                    legendItem(color: .lavender.opacity(0.6), label: "지난/미래 대운")
                }
            }
        }
    }

    private var placeholderChart: some View {
        VStack(spacing: 8) {
            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.line)
                    .frame(height: CGFloat(40 + i * 8))
            }
        }
        .frame(height: 160)
        .overlay(
            Text("사주를 먼저 분석해주세요")
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
        )
    }

    private var decadeList: some View {
        VStack(spacing: 8) {
            ForEach(daeWoon) { dw in
                DaeWoonRow(
                    daeWoon: dw,
                    currentAge: currentAge,
                    isSelected: selectedDaeWoon?.id == dw.id
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDaeWoon = selectedDaeWoon?.id == dw.id ? nil : dw
                    }
                }
            }

            if daeWoon.isEmpty {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 36))
                .foregroundStyle(.ink4)
            Text("사주를 분석하면\n대운 정보를 볼 수 있어요")
                .font(.pretendard(14))
                .foregroundStyle(.ink3)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 16, height: 10)
            Text(label)
                .font(.pretendard(11))
                .foregroundStyle(.ink3)
        }
    }

    private func loadDaeWoon() {
        guard let profile = user?.sajuProfile,
              let data = profile.daeWoonJSON.data(using: .utf8) else { return }
        daeWoon = (try? JSONDecoder().decode([DaeWoon].self, from: data)) ?? []
    }
}

// MARK: - DaeWoonRow

struct DaeWoonRow: View {
    let daeWoon: DaeWoon
    let currentAge: Int
    var isSelected: Bool

    private var isCurrent: Bool {
        daeWoon.startAge <= currentAge && daeWoon.startAge + 10 > currentAge
    }

    private var phaseLabel: String {
        if daeWoon.startAge + 10 <= currentAge { return "지난 대운" }
        if isCurrent { return "현재 대운" }
        return "미래 대운"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Stem-branch badge
                VStack(spacing: 2) {
                    Text(stemChar)
                        .font(.serifKR(18, .semibold))
                        .foregroundStyle(isCurrent ? .white : .ink1)
                    Text(branchChar)
                        .font(.serifKR(18, .semibold))
                        .foregroundStyle(isCurrent ? .white : .ink1)
                }
                .frame(width: 44, height: 56)
                .background(isCurrent ? Color.lavenderDeep : Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isCurrent ? .clear : Color.line, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(daeWoon.startAge)세 — \(daeWoon.startAge + 9)세")
                            .font(.pretendard(15, .semibold))
                            .foregroundStyle(.ink1)
                        Tag(
                            text: phaseLabel,
                            background: isCurrent ? Color.lavenderSoft : Color.surface,
                            foreground: isCurrent ? Color.lavenderDeep : Color.ink3
                        )
                    }
                    Text("\(daeWoon.startYear)년부터 시작")
                        .font(.pretendard(12))
                        .foregroundStyle(.ink3)
                    Text(elementDescription)
                        .font(.pretendard(13))
                        .foregroundStyle(.ink2)
                }

                Spacer()

                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.ink4)
            }
            .padding(16)

            if isSelected {
                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text(expandedDescription)
                        .font(.pretendard(13))
                        .foregroundStyle(.ink2)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isCurrent ? Color.lavender : Color.line, lineWidth: isCurrent ? 1.5 : 1)
        )
        .shadow(color: isCurrent ? Color.lavender.opacity(0.2) : .black.opacity(0.03), radius: 12, y: 2)
    }

    private var stemChar: String {
        ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"][daeWoon.pillar.stem.rawValue]
    }

    private var branchChar: String {
        ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"][daeWoon.pillar.branch.rawValue]
    }

    private var elementDescription: String {
        let stem = daeWoon.pillar.stem
        return "\(stem.element.korean) 기운의 대운"
    }

    private var expandedDescription: String {
        let elem = daeWoon.pillar.stem.element
        return switch elem {
        case .wood:  "성장과 발전의 기운이 강한 시기입니다. 새로운 시작과 학습에 좋은 흐름이 이어집니다."
        case .fire:  "열정과 활동력이 넘치는 시기입니다. 사회적 활동과 인간관계에서 두각을 나타냅니다."
        case .earth: "안정과 내실을 다지는 시기입니다. 성급한 결정보다 꾸준한 노력이 빛을 발합니다."
        case .metal: "결단력과 추진력이 강한 시기입니다. 재정적 관리와 규율이 중요한 시기입니다."
        case .water: "지혜와 유연성이 돋보이는 시기입니다. 흐름에 맡기며 인내하면 좋은 결과가 따릅니다."
        }
    }
}

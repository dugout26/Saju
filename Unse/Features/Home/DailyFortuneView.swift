import SwiftUI
import SwiftData

// MARK: - DailyFortuneView

struct DailyFortuneView: View {
    var user: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @State private var showChat = false
    @State private var showTimeline = false
    @State private var showShare = false
    @State private var serverOneLiner: String?

    private var nickname: String { user?.nickname ?? "사용자" }

    private var snapshot: DailyFortuneSnapshot? {
        guard let saju = user?.sajuProfile?.computed else { return nil }
        let base = DailyFortuneEngine.compute(saju: saju)
        // 서버 호출 결과(있으면) → mock oneLiner 대체
        guard let server = serverOneLiner else { return base }
        return DailyFortuneSnapshot(
            date: base.date, dayPillar: base.dayPillar, luckyElement: base.luckyElement,
            theme: base.theme, luckyDirectionKorean: base.luckyDirectionKorean,
            luckyDirectionHanja: base.luckyDirectionHanja,
            luckyTimeStartHour: base.luckyTimeStartHour, luckyTimeEndHour: base.luckyTimeEndHour,
            luckyTimeBranchLabel: base.luckyTimeBranchLabel, luckyNumbers: base.luckyNumbers,
            avoid: base.avoid, oneLiner: server
        )
    }

    var body: some View {
        NavigationStack {
            if let snap = snapshot {
                content(snap: snap)
                    .task { await loadOneLiner(snap: snap) }
            } else {
                Text("사주 정보가 없습니다")
                    .foregroundStyle(.ink3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bg.ignoresSafeArea())
            }
        }
    }

    private func loadOneLiner(snap: DailyFortuneSnapshot) async {
        guard serverOneLiner == nil else { return }   // 한 번만 호출
        if let dto = try? await APIClient.shared.fetchDailyOneliner(snapshot: snap) {
            serverOneLiner = dto.one_liner
        }
    }

    private func content(snap: DailyFortuneSnapshot) -> some View {
        let theme = snap.theme
        return ScrollView {
            VStack(spacing: 12) {
                dateGreeting(theme: theme)
                oneLinerCard(snap: snap, theme: theme)
                luckyGrid(snap: snap, theme: theme)
                avoidCard(snap: snap)
                ctaButtons(theme: theme)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(theme.gradient.ignoresSafeArea())
        .navigationTitle("오늘의 운세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.ink1)
                }
                .minTapTarget()
            }
        }
        .navigationDestination(isPresented: $showChat)     { ChatView(user: user) }
        .navigationDestination(isPresented: $showTimeline) { TimelineView(user: user) }
        .sheet(isPresented: $showShare)                    { ShareCardView(theme: theme, nickname: nickname) }
    }

    // MARK: - Sub-views

    private func dateGreeting(theme: FortuneTheme) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date(), format: .dateTime.year().month().day().weekday(.wide))
                .font(.pretendard(12, .medium))
                .foregroundStyle(.ink3)

            Group {
                Text("오늘은 ") +
                Text(theme.name).foregroundStyle(theme.accent) +
                Text("의\n기운이 도는 하루")
            }
            .font(.serifKR(26, .semibold))
            .foregroundStyle(.ink1)
            .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func oneLinerCard(snap: DailyFortuneSnapshot, theme: FortuneTheme) -> some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(theme.soft).opacity(0.7)
                .frame(width: 120, height: 120)
                .offset(x: 30, y: -30)

            VStack(alignment: .leading, spacing: 12) {
                Tag(text: "한 줄 운세", background: theme.soft, foreground: theme.accent)
                Text(snap.oneLiner)
                    .font(.serifKR(19, .medium))
                    .foregroundStyle(.ink1)
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.04), radius: 30, y: 8)
        .clipped()
    }

    private func luckyGrid(snap: DailyFortuneSnapshot, theme: FortuneTheme) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            luckyColorCard(theme: theme)
            luckyDirectionCard(snap: snap, theme: theme)
            luckyTimeCard(snap: snap)
            luckyNumberCard(snap: snap, theme: theme)
        }
    }

    private func luckyColorCard(theme: FortuneTheme) -> some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 색")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.soft)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.accent.opacity(0.3))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.name)
                            .font(.serifKR(16, .semibold))
                            .foregroundStyle(.ink1)
                        Text(theme.hex)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.ink3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func luckyDirectionCard(snap: DailyFortuneSnapshot, theme: FortuneTheme) -> some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 방향")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                HStack(spacing: 10) {
                    Compass(direction: compassDirection(for: snap.luckyElement), accent: theme.accent, soft: theme.soft)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.luckyDirectionKorean).font(.serifKR(16, .semibold)).foregroundStyle(.ink1)
                        Text(snap.luckyDirectionHanja).font(.pretendard(11)).foregroundStyle(.ink3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func luckyTimeCard(snap: DailyFortuneSnapshot) -> some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 시간")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                Text(String(format: "%02d:00 — %02d:00", snap.luckyTimeStartHour, snap.luckyTimeEndHour))
                    .font(.serifKR(18, .semibold))
                    .foregroundStyle(.ink1)
                Text(snap.luckyTimeBranchLabel)
                    .font(.pretendard(11))
                    .foregroundStyle(.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func luckyNumberCard(snap: DailyFortuneSnapshot, theme: FortuneTheme) -> some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 숫자")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    ForEach(Array(snap.luckyNumbers.enumerated()), id: \.offset) { idx, num in
                        if idx > 0 {
                            Text("·").font(.pretendard(18)).foregroundStyle(.ink4)
                        }
                        Text("\(num)").font(.serifKR(28, .semibold)).foregroundStyle(theme.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func avoidCard(snap: DailyFortuneSnapshot) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: 0xFBE8E8))
                    .frame(width: 32, height: 32)
                Text("!")
                    .font(.pretendard(16, .semibold))
                    .foregroundStyle(Color(hex: 0xC97070))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("피해야 할 것")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                Text(snap.avoid)
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.line, style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
    }

    private func ctaButtons(theme: FortuneTheme) -> some View {
        VStack(spacing: 8) {
            PrimaryButton(title: "AI에게 더 자세히 물어보기", color: theme.accent) {
                showChat = true
            }
            HStack(spacing: 8) {
                OutlineButton(title: "주간 흐름") { showTimeline = true }
                OutlineButton(title: "내일 미리보기") {}
            }
        }
        .padding(.top, 8)
    }

    private func compassDirection(for element: Element) -> CompassDirection {
        switch element {
        case .wood:  .east
        case .fire:  .south
        case .metal: .west
        case .water: .north
        case .earth: .east   // Compass에 center 없음 → east로 fallback
        }
    }
}

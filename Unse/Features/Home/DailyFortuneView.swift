import SwiftUI
import SwiftData

// MARK: - DailyFortuneView

struct DailyFortuneView: View {
    var user: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var sub
    @State private var showChat = false
    @State private var showTimeline = false
    @State private var showShare = false
    @State private var showPaywall = false
    @State private var snapshot: DailyFortuneSnapshot?
    @State private var tomorrowSnapshot: DailyFortuneSnapshot?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var rewardedLoader = RewardedAdLoader()

    private var nickname: String { user?.nickname ?? "사용자" }

    var body: some View {
        NavigationStack {
            Group {
                if let snap = snapshot {
                    content(snap: snap)
                } else if isLoading {
                    AIAnalysisLoadingView()
                } else {
                    VStack(spacing: 10) {
                        Text("운세를 불러오지 못했어요")
                            .font(.pretendard(14))
                            .foregroundStyle(.ink2)
                        if let loadError {
                            Text(loadError)
                                .font(.pretendard(11, .medium))
                                .foregroundStyle(.red.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        Button("다시 시도") {
                            Task { await loadFortune() }
                        }
                        .font(.pretendard(13, .semibold))
                        .foregroundStyle(.lavenderDeep)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bg.ignoresSafeArea())
                }
            }
            .task { await loadFortune() }
        }
    }

    private func loadFortune() async {
        guard user?.sajuProfile != nil else { isLoading = false; return }
        isLoading = true
        loadError = nil
        let dayPillar = DailyFortuneEngine.dayPillarString()
        do {
            let dto = try await APIClient.shared.fetchDailyFortune(dayPillarOfDate: dayPillar)
            snapshot = DailyFortuneSnapshot(dto: dto)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func loadTomorrow() async {
        guard tomorrowSnapshot == nil else { return }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayPillar = DailyFortuneEngine.dayPillarString(for: tomorrow)
        if let dto = try? await APIClient.shared.fetchDailyFortune(
            dayPillarOfDate: dayPillar,
            forDate: tomorrow
        ) {
            tomorrowSnapshot = DailyFortuneSnapshot(dto: dto)
        }
    }

    private func content(snap: DailyFortuneSnapshot) -> some View {
        let theme = snap.theme
        return ScrollView {
            VStack(spacing: 12) {
                dateGreeting(snap: snap, theme: theme)
                oneLinerCard(snap: snap, theme: theme)
                luckyGrid(snap: snap, theme: theme)
                avoidCard(snap: snap)
                ctaButtons(theme: theme)
                if !sub.isPremium {
                    BannerAdView(unitId: AdsManager.bannerUnitId)
                        .frame(height: 50)
                        .padding(.top, 8)
                }
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
        .sheet(isPresented: $showPaywall)                  { PaywallView().environment(sub) }
        .sheet(item: $tomorrowSnapshot) { snap in
            TomorrowFortuneSheet(snapshot: snap)
        }
    }

    // MARK: - Sub-views

    private func dateGreeting(snap: DailyFortuneSnapshot, theme: FortuneTheme) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date(), format: .dateTime.year().month().day().weekday(.wide))
                .font(.pretendard(12, .medium))
                .foregroundStyle(.ink3)

            Group {
                Text("오늘은 ") +
                Text(snap.luckyColorName).foregroundStyle(theme.accent) +
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
            luckyColorCard(snap: snap, theme: theme)
            luckyDirectionCard(snap: snap, theme: theme)
            luckyTimeCard(snap: snap)
            luckyNumberCard(snap: snap, theme: theme)
        }
    }

    private func luckyColorCard(snap: DailyFortuneSnapshot, theme: FortuneTheme) -> some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 색")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hexString: snap.luckyColorHex) ?? theme.soft)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.luckyColorName)
                            .font(.serifKR(16, .semibold))
                            .foregroundStyle(.ink1)
                        Text(snap.luckyColorHex)
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
                    Compass(direction: compassDirection(for: snap.luckyDirectionKorean), accent: theme.accent, soft: theme.soft)
                    Text(snap.luckyDirectionKorean)
                        .font(.serifKR(16, .semibold))
                        .foregroundStyle(.ink1)
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
                Text(snap.luckyTimeLabel)
                    .font(.pretendard(11))
                    .foregroundStyle(.ink3)
                    .lineLimit(1)
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
                OutlineButton(title: "내일 미리보기") {
                    if sub.isPremium {
                        Task { await loadTomorrow() }
                    } else {
                        // 광고 시청 후 보상으로 내일 운세. load 실패 시에도 silent grant.
                        var granted = false
                        rewardedLoader.loadAndShow(unitId: AdsManager.rewardedUnitId) {
                            granted = true
                            Task { await loadTomorrow() }
                        }
                        // 광고 자체가 안 뜨면 (load fail) 1.5초 후 silent grant
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            if !granted { await loadTomorrow() }
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private func compassDirection(for korean: String) -> CompassDirection {
        switch korean {
        case "동쪽": .east
        case "서쪽": .west
        case "남쪽": .south
        case "북쪽": .north
        default:    .east   // "중앙" 등 fallback
        }
    }
}

// MARK: - AI 분석 진행 모션 (매일 운세 진입 시)

private struct AIAnalysisLoadingView: View {
    @State private var step = 0
    @State private var floating = false

    private let messages = [
        "오늘의 일진을 읽는 중...",
        "사주와 일진의 흐름을 비교 중...",
        "오늘의 행운 색을 고르는 중...",
        "한 줄 운세를 다듬는 중...",
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // 떠다니는 한자들
            HStack(spacing: 8) {
                ForEach(["甲","乙","丙","丁","戊","己"].indices, id: \.self) { i in
                    Text(["甲","乙","丙","丁","戊","己"][i])
                        .font(.serifKR(20, .medium))
                        .foregroundStyle(.lavenderDeep)
                        .frame(width: 36, height: 36)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .lavenderDeep.opacity(0.15), radius: 12, y: 4)
                        .offset(y: floating ? -8 : 0)
                        .animation(
                            .easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: floating
                        )
                }
            }
            .onAppear { floating = true }

            VStack(spacing: 8) {
                Text("AI가 오늘의 운세를 풀고 있어요")
                    .font(.serifKR(20, .semibold))
                    .foregroundStyle(.ink1)
                Text(messages[step % messages.count])
                    .font(.pretendard(13))
                    .foregroundStyle(.ink3)
                    .id(step)
                    .transition(.opacity)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.lavenderSoft, .bg], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .task {
            // task가 cancel되면 sleep이 throw — try?로 nil 받고 loop가 step을 빠르게
            // 증가시키는 race를 방지하기 위해 do/catch로 cleanup 후 return.
            for _ in 0..<20 {
                do {
                    try await Task.sleep(for: .seconds(1.0))
                } catch {
                    return
                }
                withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
            }
        }
    }
}

// MARK: - TomorrowFortuneSheet (간단 미리보기)

private struct TomorrowFortuneSheet: View {
    let snapshot: DailyFortuneSnapshot
    @Environment(\.dismiss) private var dismiss

    private var tomorrowString: String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: tomorrow)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(tomorrowString)
                        .font(.pretendard(13, .medium))
                        .foregroundStyle(.ink3)
                        .padding(.top, 8)
                    Text(snapshot.oneLiner)
                        .font(.serifKR(20, .medium))
                        .foregroundStyle(.ink1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        infoRow(icon: "🎨", label: "행운의 색", value: snapshot.luckyColorName)
                        infoRow(icon: "🧭", label: "행운의 방향", value: snapshot.luckyDirectionKorean)
                        infoRow(icon: "⏰", label: "행운의 시간", value: snapshot.luckyTimeLabel)
                        infoRow(icon: "🔢", label: "행운의 숫자", value: snapshot.luckyNumbers.map(String.init).joined(separator: " · "))
                        infoRow(icon: "⚠️", label: "피해야 할 것", value: snapshot.avoid)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .background(snapshot.theme.gradient.ignoresSafeArea())
            .navigationTitle("내일 미리보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .font(.pretendard(15))
                        .foregroundStyle(.ink1)
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.system(size: 18))
            Text(label)
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
            Spacer()
            Text(value)
                .font(.pretendard(14, .semibold))
                .foregroundStyle(.ink1)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color hex string init

private extension Color {
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v)
    }
}

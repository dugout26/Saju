import SwiftUI
import SwiftData

// MARK: - DailyFortuneView

struct DailyFortuneView: View {
    var user: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @State private var fortune: DailyFortune?
    @State private var theme: FortuneTheme = .lavender
    @State private var showChat = false
    @State private var showTimeline = false
    @State private var showShare = false

    private let nickname: String = "지수"  // TODO: from user profile

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    dateGreeting
                    oneLinerCard
                    luckyGrid
                    avoidCard
                    ctaButtons
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
    }

    // MARK: - Sub-views

    private var dateGreeting: some View {
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

    private var oneLinerCard: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(theme.soft).opacity(0.7)
                .frame(width: 120, height: 120)
                .offset(x: 30, y: -30)

            VStack(alignment: .leading, spacing: 12) {
                Tag(text: "한 줄 운세", background: theme.soft, foreground: theme.accent)
                Text("차분히 듣는 자세가\n예상 밖의 인연을 부르는 날입니다.")
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

    private var luckyGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            luckyColorCard
            luckyDirectionCard
            luckyTimeCard
            luckyNumberCard
        }
    }

    private var luckyColorCard: some View {
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

    private var luckyDirectionCard: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 방향")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                HStack(spacing: 10) {
                    Compass(direction: .east, accent: theme.accent, soft: theme.soft)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("동쪽").font(.serifKR(16, .semibold)).foregroundStyle(.ink1)
                        Text("東 · 木").font(.pretendard(11)).foregroundStyle(.ink3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var luckyTimeCard: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 시간")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                Text("15:00 — 17:00")
                    .font(.serifKR(18, .semibold))
                    .foregroundStyle(.ink1)
                Text("申時 · 신시")
                    .font(.pretendard(11))
                    .foregroundStyle(.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var luckyNumberCard: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("행운의 숫자")
                    .font(.pretendard(11, .semibold))
                    .foregroundStyle(.ink3)
                    .tracking(0.3)
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("3").font(.serifKR(28, .semibold)).foregroundStyle(theme.accent)
                    Text("·").font(.pretendard(18)).foregroundStyle(.ink4)
                    Text("8").font(.serifKR(28, .semibold)).foregroundStyle(theme.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var avoidCard: some View {
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
                Text("충동적인 금전 결정")
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

    private var ctaButtons: some View {
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
}

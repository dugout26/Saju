import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @State private var slide = 0
    @State private var showBirthInfo = false

    private let slides: [OnboardSlide] = [
        .init(eyebrow: "매일 아침",
              titleA: "당신의", titleB: "행운 색을",
              subtitle: "사주 8글자에서 풀어낸\n오늘의 색·방향·시간",
              art: .colors),
        .init(eyebrow: "AI 해설",
              titleA: "진짜 사주를", titleB: "풀어드려요",
              subtitle: "카톡 운세 말고,\n진짜 명리학 기반 풀이",
              art: .chat),
        .init(eyebrow: "평생의 흐름",
              titleA: "지금이", titleB: "어떤 시기인지",
              subtitle: "대운 그래프로 보는\n인생의 정점과 저점",
              art: .timeline),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                skipButton
                artPager
                copySection
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationDestination(isPresented: $showBirthInfo) {
                BirthInfoView()
            }
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button("건너뛰기") { showBirthInfo = true }
                .font(.pretendard(15, .medium))
                .foregroundStyle(.ink3)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
        }
    }

    private var artPager: some View {
        TabView(selection: $slide) {
            ForEach(slides.indices, id: \.self) { i in
                OnboardArt(kind: slides[i].art)
                    .tag(i)
                    .padding(.horizontal, Spacing.xxxl)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }

    private var copySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Tag(text: slides[slide].eyebrow)
                .padding(.bottom, 14)

            Text("\(slides[slide].titleA)\n\(slides[slide].titleB)")
                .font(.serifKR(34, .semibold))
                .foregroundStyle(.ink1)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            Text(slides[slide].subtitle)
                .font(.pretendard(15))
                .foregroundStyle(.ink2)
                .lineSpacing(6)
                .padding(.top, 14)
                .fixedSize(horizontal: false, vertical: true)

            PageDots(count: slides.count, current: slide)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
                .padding(.bottom, 20)

            PrimaryButton(title: slide < 2 ? "다음" : "시작하기") {
                if slide < 2 {
                    withAnimation { slide += 1 }
                } else {
                    showBirthInfo = true
                }
            }
        }
        .padding(.horizontal, Spacing.xxxl)
        .padding(.bottom, 32)
    }
}

// MARK: - OnboardSlide

struct OnboardSlide {
    let eyebrow: String
    let titleA: String
    let titleB: String
    let subtitle: String
    let art: ArtKind

    enum ArtKind { case colors, chat, timeline }
}

// MARK: - OnboardArt

struct OnboardArt: View {
    let kind: OnboardSlide.ArtKind

    var body: some View {
        switch kind {
        case .colors:   OnboardArtColors()
        case .chat:     OnboardArtChat()
        case .timeline: OnboardArtTimeline()
        }
    }
}

// MARK: - OnboardArtColors (floating color cards)

struct OnboardArtColors: View {
    private let cards: [(color: Color, label: String, angle: Double, x: CGFloat, y: CGFloat)] = [
        (.lavender, "라벤더", -12, -65,  -60),
        (.peach,    "피치",     6,  40,  -15),
        (.mint,     "민트",    -8, -35,   60),
        (.cream,    "크림",    10,  55,   65),
    ]

    var body: some View {
        ZStack {
            ForEach(cards.indices, id: \.self) { i in
                let c = cards[i]
                RoundedRectangle(cornerRadius: 22)
                    .fill(c.color)
                    .frame(width: 130, height: 170)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TODAY")
                                .font(.pretendard(11, .semibold))
                                .foregroundStyle(.black.opacity(0.5))
                                .tracking(1)
                            Text(c.label)
                                .font(.serifKR(20, .semibold))
                                .foregroundStyle(.ink1)
                        }
                        .padding(14)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 30, y: 12)
                    .rotationEffect(.degrees(c.angle))
                    .offset(x: c.x, y: c.y)
            }
        }
        .frame(width: 280, height: 280)
    }
}

// MARK: - OnboardArtChat

struct OnboardArtChat: View {
    var body: some View {
        VStack(spacing: 10) {
            // User bubble
            HStack {
                Spacer()
                Text("올해 이직해도 괜찮을까요?")
                    .font(.pretendard(14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.ink1)
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomLeft]))
            }

            // Assistant bubble
            HStack {
                Text("**戊土 일간**에\n**木 대운**이 들어오는 시기네요.\n새 시작이 잘 풀리는 흐름으로 해석됩니다.")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
                    .lineSpacing(4)
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    .background(Color.surface)
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight]))
                    .shadow(color: .black.opacity(0.04), radius: 16, y: 4)
                Spacer()
            }

            // Typing indicator
            HStack {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().fill(Color.lavenderDeep).frame(width: 6, height: 6)
                            .opacity(Double(3 - i) / 3.0)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.04), radius: 16, y: 4)
                Spacer()
            }
        }
        .frame(maxWidth: 280)
    }
}

// MARK: - OnboardArtTimeline

struct OnboardArtTimeline: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height

            // Zone backgrounds
            let zones: [(Color, CGFloat)] = [(.lavenderSoft, 0.3), (.peachSoft, 0.4), (.mintSoft, 0.3)]
            for (i, (color, opacity)) in zones.enumerated() {
                let x = CGFloat(i) * w / 3
                let rect = CGRect(x: x, y: 20, width: w/3, height: h-40)
                ctx.fill(Path(rect), with: .color(color.opacity(opacity)))
            }

            // Lines (simplified sine-like paths)
            func drawLine(_ points: [(CGFloat, CGFloat)], color: Color) {
                var path = Path()
                path.move(to: CGPoint(x: points[0].0 * w, y: points[0].1 * h))
                for p in points.dropFirst() {
                    path.addLine(to: CGPoint(x: p.0 * w, y: p.1 * h))
                }
                ctx.stroke(path, with: .color(color), lineWidth: 2.5)
            }
            drawLine([(0,0.6),(0.3,0.4),(0.6,0.3),(1.0,0.5)], color: .lavenderDeep)
            drawLine([(0,0.7),(0.3,0.65),(0.6,0.45),(1.0,0.65)], color: .peachDeep)
            drawLine([(0,0.5),(0.3,0.55),(0.6,0.35),(1.0,0.45)], color: .mintDeep)

            // Current position marker
            let cx = w * 0.43
            ctx.stroke(Path { p in p.move(to: CGPoint(x: cx, y: 20)); p.addLine(to: CGPoint(x: cx, y: h-20)) },
                       with: .color(.ink1), style: StrokeStyle(lineWidth: 1.5, dash: [3]))
            ctx.fill(Path(ellipseIn: CGRect(x: cx-5, y: h*0.3-5, width: 10, height: 10)), with: .color(.ink1))
        }
        .frame(maxWidth: 300, maxHeight: 220)
    }
}

// MARK: - Helpers

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

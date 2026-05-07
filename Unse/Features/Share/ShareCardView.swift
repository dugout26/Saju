import SwiftUI

struct ShareCardView: View {
    let theme: FortuneTheme
    let nickname: String

    @Environment(\.dismiss) private var dismiss
    @State private var isRendering = false
    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cardPreview
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        PrimaryButton(title: "이미지로 저장", color: theme.accent) {
                            Task { await saveImage() }
                        }
                        GhostButton(title: "다른 앱으로 공유") {
                            Task { await shareImage() }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("공유하기")
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

    // MARK: - Card

    private var cardPreview: some View {
        ShareCard(theme: theme, nickname: nickname)
            .frame(width: cardWidth, height: cardWidth * 1.25)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: theme.accent.opacity(0.2), radius: 30, y: 10)
            .padding(.horizontal, 32)
    }

    private var cardWidth: CGFloat {
        UIScreen.main.bounds.width - 64
    }

    // MARK: - Actions

    @MainActor
    private func saveImage() async {
        isRendering = true
        defer { isRendering = false }

        let image = renderCard()
        guard let image else { return }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    @MainActor
    private func shareImage() async {
        let image = renderCard()
        guard let image else { return }

        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    @MainActor
    private func renderCard() -> UIImage? {
        let card = ShareCard(theme: theme, nickname: nickname)
            .frame(width: 390, height: 488)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}

// MARK: - ShareCard

struct ShareCard: View {
    let theme: FortuneTheme
    let nickname: String

    private var todayString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 EEEE"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            // Decorative blobs
            Circle()
                .fill(theme.soft.opacity(0.6))
                .frame(width: 200)
                .offset(x: 120, y: -140)

            Circle()
                .fill(theme.accent.opacity(0.15))
                .frame(width: 150)
                .offset(x: -100, y: 160)

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("운세")
                            .font(.pretendard(12, .semibold))
                            .foregroundStyle(theme.accent)
                        Text(todayString)
                            .font(.pretendard(11))
                            .foregroundStyle(.ink3)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.soft)
                            .frame(width: 32, height: 32)
                        Text("戊")
                            .font(.serifKR(16, .semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
                .padding(.bottom, 28)

                // One-liner
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.accent)
                            .frame(width: 3, height: 16)
                        Text("오늘의 한 마디")
                            .font(.pretendard(12, .semibold))
                            .foregroundStyle(theme.accent)
                    }
                    Text("차분히 듣는 자세가\n예상 밖의 인연을 부르는 날입니다.")
                        .font(.serifKR(20, .semibold))
                        .foregroundStyle(.ink1)
                        .lineSpacing(6)
                }
                .padding(.bottom, 28)

                // Lucky items
                HStack(spacing: 12) {
                    luckItem(icon: "🎨", label: "색상", value: theme.name)
                    luckItem(icon: "🧭", label: "방향", value: "동쪽")
                    luckItem(icon: "🔢", label: "숫자", value: "3 · 8")
                }
                .padding(.bottom, 28)

                Spacer()

                // Footer
                HStack {
                    Text("\(nickname)님의 오늘 운세")
                        .font(.pretendard(12))
                        .foregroundStyle(.ink3)
                    Spacer()
                    Text("운세 앱으로 보기 →")
                        .font(.pretendard(11, .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg)
    }

    private func luckItem(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(icon)
                .font(.system(size: 20))
            Text(label)
                .font(.pretendard(10))
                .foregroundStyle(.ink3)
            Text(value)
                .font(.serifKR(14, .semibold))
                .foregroundStyle(.ink1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.surface.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

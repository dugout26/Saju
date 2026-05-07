import SwiftUI

struct ChatView: View {
    var user: UserProfile?

    @Environment(SubscriptionManager.self) private var sub
    @State private var vm: ChatViewModel
    @State private var rewardedLoader = RewardedAdLoader()
    @State private var isWatchingAd = false
    @FocusState private var inputFocused: Bool

    let initialQuestion: String?

    init(user: UserProfile?, initialQuestion: String? = nil) {
        self.user = user
        self.initialQuestion = initialQuestion
        _vm = State(wrappedValue: ChatViewModel(nickname: user?.nickname ?? "지수"))
    }

    /// 무료 사용자: 광고 시청 후 1턴. PRO: 즉시.
    private func sendWithGate() {
        inputFocused = false
        if sub.isPremium {
            Task { await vm.send() }
            return
        }
        // 무료: 광고 시청 → 시청 완료 → 1턴 전송
        isWatchingAd = true
        rewardedLoader.loadAndShow(unitId: AdsManager.rewardedUnitId) {
            isWatchingAd = false
            Task { await vm.send() }
        }
        // 광고 load 실패 시 fallback (1.5초 후 silent grant)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if isWatchingAd {
                isWatchingAd = false
                await vm.send()
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                inputBar
            }
            .background(Color.bg.ignoresSafeArea())
            .onAppear {
                if let q = initialQuestion, vm.inputText.isEmpty {
                    vm.inputText = q
                    inputFocused = true
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.lavenderSoft)
                                .frame(width: 24, height: 24)
                            Text("戊").font(.serifKR(12, .semibold)).foregroundStyle(.lavenderDeep)
                        }
                        Text("사주 챗봇")
                            .font(.pretendard(16, .semibold))
                            .foregroundStyle(.ink1)
                        ProBadge()
                    }
                }
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vm.messages) { bubble in
                        MessageBubble(bubble: bubble)
                            .id(bubble.id)
                    }
                    if vm.isStreaming {
                        TypingIndicator()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                    }
                    suggestedQuestions
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation { proxy.scrollTo(vm.messages.last?.id) }
            }
        }
    }

    private var suggestedQuestions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("추천 질문")
                .font(.pretendard(11, .semibold))
                .foregroundStyle(.ink3)
                .padding(.horizontal, 4)
            ForEach(vm.suggestedQuestions, id: \.self) { q in
                Button { vm.useSuggestion(q) } label: {
                    Text(q)
                        .font(.pretendard(13))
                        .foregroundStyle(.ink2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 6) {
            if !sub.isPremium {
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 11))
                    Text("무료 회원: 광고 1회 시청 = 질문 1회. PRO는 무제한.")
                        .font(.pretendard(11))
                }
                .foregroundStyle(.ink3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            inputBarContent
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.bg)
        .overlay(alignment: .top) {
            Divider().opacity(0.5)
        }
    }

    private var inputBarContent: some View {
        HStack(spacing: 8) {
            HStack {
                TextField("궁금한 점을 물어보세요", text: $vm.inputText)
                    .font(.pretendard(14))
                    .focused($inputFocused)
                    .onSubmit { sendWithGate() }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.line, lineWidth: 1))

            Button(action: sendWithGate) {
                Image(systemName: sub.isPremium ? "arrow.right" : "play.rectangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.ink1)
                    .clipShape(Circle())
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isStreaming || isWatchingAd)
            .opacity(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let bubble: ChatBubble

    var isUser: Bool { bubble.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            Text(bubble.text)
                .font(.pretendard(14))
                .foregroundStyle(isUser ? .white : .ink1)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isUser ? Color.ink1 : Color.surface)
                .clipShape(RoundedCorner(
                    radius: 20,
                    corners: isUser
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight]
                ))
                .shadow(color: isUser ? .clear : .black.opacity(0.04), radius: 12, y: 2)
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.lavenderDeep)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.surface)
        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight]))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

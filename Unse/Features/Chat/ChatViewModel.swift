import Observation
import Foundation
import FirebaseCrashlytics

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatBubble] = []
    var inputText = ""
    var isStreaming = false
    var isWatchingAd = false

    let suggestedQuestions = [
        "이번 달 금전운은 어떤가요?",
        "연애운이 좋은 시기는 언제예요?",
        "저랑 잘 맞는 사람의 일간은?"
    ]

    private let client: any APIClientProtocol
    private let rewardedLoader = RewardedAdLoader()

    init(nickname: String, client: any APIClientProtocol = APIClient.shared) {
        self.client = client
        messages = [
            ChatBubble(role: .assistant,
                       text: "안녕하세요 \(nickname)님. 사주에 대해 궁금한 점을 자유롭게 물어보세요.")
        ]
    }

    /// View → VM 위임. 무료: 광고 시청 후 1턴 / PRO: 즉시.
    /// 가드 — 빈 입력 / streaming 중 / 광고 시청 중이면 무시.
    /// 광고 reward callback과 1.5s fallback이 모두 grant() 하므로 hasGranted 플래그로 한 번만 send().
    func sendGated(isPremium: Bool) {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isStreaming, !isWatchingAd else { return }

        if isPremium {
            Task { await send() }
            return
        }

        isWatchingAd = true
        var hasGranted = false
        let grant: @MainActor () -> Void = { [weak self] in
            guard let self, !hasGranted else { return }
            hasGranted = true
            self.isWatchingAd = false
            Task { await self.send() }
        }
        rewardedLoader.loadAndShow(unitId: AdsManager.rewardedUnitId) { grant() }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            grant()
        }
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        inputText = ""
        messages.append(ChatBubble(role: .user, text: text))

        isStreaming = true
        defer { isStreaming = false }

        var assistantBubble = ChatBubble(role: .assistant, text: "")
        messages.append(assistantBubble)
        let idx = messages.count - 1

        do {
            let storageMessages = messages.dropLast().map { msg in
                ["role": msg.role == .user ? "user" : "assistant", "content": msg.text]
            }
            for try await delta in await client.chatStream(messages: Array(storageMessages)) {
                assistantBubble.text += delta
                messages[idx] = assistantBubble
            }
        } catch {
            Crashlytics.crashlytics().record(error: error)
            messages[idx].text = "잠시 오류가 발생했어요. 다시 시도해주세요."
        }
    }

    func useSuggestion(_ text: String) {
        inputText = text
    }
}

struct ChatBubble: Identifiable {
    let id = UUID()
    var text: String
    let role: Role

    enum Role { case user, assistant }

    init(role: Role, text: String) {
        self.role = role
        self.text = text
    }
}

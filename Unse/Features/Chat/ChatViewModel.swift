import Observation
import Foundation

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatBubble] = []
    var inputText = ""
    var isStreaming = false

    let suggestedQuestions = [
        "이번 달 금전운은 어떤가요?",
        "연애운이 좋은 시기는 언제예요?",
        "저랑 잘 맞는 사람의 일간은?",
    ]

    init(nickname: String) {
        messages = [
            ChatBubble(role: .assistant,
                       text: "안녕하세요 \(nickname)님. 사주에 대해 궁금한 점을 자유롭게 물어보세요.")
        ]
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
            for try await delta in await APIClient.shared.chatStream(messages: Array(storageMessages)) {
                assistantBubble.text += delta
                messages[idx] = assistantBubble
            }
        } catch {
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

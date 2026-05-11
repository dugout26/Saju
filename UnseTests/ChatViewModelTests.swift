import Testing
import Foundation
@testable import Unse

@Suite("ChatViewModel — streaming + 입력 가드")
@MainActor
struct ChatViewModelTests {

    @Test("init은 닉네임이 포함된 assistant greeting 한 건으로 시작")
    func init_greeting() {
        let vm = ChatViewModel(nickname: "지수", client: MockAPIClient())
        #expect(vm.messages.count == 1)
        #expect(vm.messages.first?.role == .assistant)
        #expect(vm.messages.first?.text.contains("지수") == true)
    }

    @Test("useSuggestion은 inputText에 텍스트 설정")
    func useSuggestion_setsInput() {
        let vm = ChatViewModel(nickname: "지수", client: MockAPIClient())
        vm.useSuggestion("연애운은?")
        #expect(vm.inputText == "연애운은?")
    }

    @Test("send()는 inputText가 공백/빈 문자열이면 무시")
    func send_emptyInputGuard() async {
        let mock = MockAPIClient()
        await mock.setChatStream(chunks: ["should-not-appear"])
        let vm = ChatViewModel(nickname: "지수", client: mock)
        let initialCount = vm.messages.count

        vm.inputText = "   "
        await vm.send()

        #expect(vm.messages.count == initialCount)
        #expect(!vm.isStreaming)
    }

    @Test("send() 성공 시 chunks를 assistant bubble.text에 누적, isStreaming 해제")
    func send_streamingAccumulates() async {
        let mock = MockAPIClient()
        await mock.setChatStream(chunks: ["안녕", "하세", "요"])
        let vm = ChatViewModel(nickname: "지수", client: mock)
        vm.inputText = "테스트 질문"

        await vm.send()

        #expect(vm.messages.count == 3)
        #expect(vm.messages[1].role == .user)
        #expect(vm.messages[1].text == "테스트 질문")
        #expect(vm.messages[2].role == .assistant)
        #expect(vm.messages[2].text == "안녕하세요")
        #expect(vm.inputText == "")
        #expect(!vm.isStreaming)
    }

    @Test("send() 실패 시 assistant bubble을 에러 안내 문구로 대체")
    func send_errorReplacesBubbleText() async {
        let mock = MockAPIClient()
        let err = NSError(domain: "test", code: 500)
        await mock.setChatStream(chunks: [], error: err)
        let vm = ChatViewModel(nickname: "지수", client: mock)
        vm.inputText = "에러 시나리오"

        await vm.send()

        // user message + error placeholder assistant bubble
        #expect(vm.messages.count == 3)
        #expect(vm.messages[2].role == .assistant)
        #expect(vm.messages[2].text == "잠시 오류가 발생했어요. 다시 시도해주세요.")
        #expect(!vm.isStreaming)
    }
}

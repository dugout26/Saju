import Testing
@testable import Unse

@Suite("SajuEditError — 사용자 메시지 검증")
struct SajuEditErrorTests {

    @Test("profileMissing 한국어 메시지")
    func profileMissing_message() {
        let error = SajuEditError.profileMissing
        #expect(error.errorDescription == "사주 정보를 찾을 수 없어요. 다시 시도해주세요.")
    }

    @Test("encodingFailed 한국어 메시지")
    func encodingFailed_message() {
        let error = SajuEditError.encodingFailed
        #expect(error.errorDescription == "사주 데이터 변환에 실패했어요. 다시 시도해주세요.")
    }

    @Test("LocalizedError 프로토콜 준수 — errorDescription nil 아님")
    func localizedError_conformance() {
        let errors: [SajuEditError] = [.profileMissing, .encodingFailed]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

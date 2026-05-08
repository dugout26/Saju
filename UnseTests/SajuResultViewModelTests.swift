import Testing
import Foundation
@testable import Unse

@Suite("SajuResultViewModel — async loading with mock")
@MainActor
struct SajuResultViewModelTests {

    @Test("loadReadings 성공 시 stage1Text + stage2Text 설정")
    func loadReadings_success() async {
        let mock = MockAPIClient()
        await mock.setSajuReading(.success("성공 풀이"))
        let vm = SajuResultViewModel(client: mock)
        await vm.loadReadings(saju: makeSaju(), nickname: "테스트")
        // async let s1, s2 모두 같은 stub 사용 → 둘 다 같은 값
        #expect(vm.stage1Text == "성공 풀이")
        #expect(vm.stage2Text == "성공 풀이")
        #expect(await mock.sajuReadingCallCount == 2)
    }

    @Test("loadReadings 실패 시 stage 텍스트 nil 유지 (silent fallback)")
    func loadReadings_failure() async {
        let mock = MockAPIClient()
        let error = NSError(domain: "test", code: 500)
        await mock.setSajuReading(.failure(error))
        let vm = SajuResultViewModel(client: mock)
        await vm.loadReadings(saju: makeSaju(), nickname: "테스트")
        #expect(vm.stage1Text == nil)
        #expect(vm.stage2Text == nil)
    }

    private func makeSaju() -> SajuComputed {
        let result = Manse.calculate(year: 1990, month: 3, day: 15, hour: 12, minute: 0)
        return result.saju
    }
}

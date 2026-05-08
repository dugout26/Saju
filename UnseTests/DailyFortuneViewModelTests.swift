import Testing
import Foundation
@testable import Unse

@Suite("DailyFortuneViewModel — async loading with mock")
@MainActor
struct DailyFortuneViewModelTests {

    @Test("hasSajuProfile false면 loading 즉시 종료, snapshot 미생성")
    func loadFortune_noSajuProfile() async {
        let mock = MockAPIClient()
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: false)
        #expect(vm.snapshot == nil)
        #expect(!vm.isLoading)
        #expect(vm.loadError == nil)
        #expect(await mock.dailyFortuneCallCount == 0)
    }

    @Test("loadFortune 성공 시 snapshot 설정, isLoading false")
    func loadFortune_success() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture(oneLiner: "테스트 운세")))
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: true)
        #expect(vm.snapshot != nil)
        #expect(vm.snapshot?.oneLiner == "테스트 운세")
        #expect(!vm.isLoading)
        #expect(vm.loadError == nil)
        #expect(await mock.dailyFortuneCallCount == 1)
    }

    @Test("loadFortune 실패 시 loadError 설정")
    func loadFortune_failure() async {
        let mock = MockAPIClient()
        let error = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        await mock.setDailyFortune(.failure(error))
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: true)
        #expect(vm.snapshot == nil)
        #expect(vm.loadError != nil)
        #expect(!vm.isLoading)
    }

    @Test("loadTomorrow 캐시 hit (snapshot 이미 있으면 호출 X)")
    func loadTomorrow_cacheHit() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        let vm = DailyFortuneViewModel(client: mock)
        // 첫 호출 — snapshot 설정
        await vm.loadTomorrow()
        let firstCount = await mock.dailyFortuneCallCount
        // 두 번째 호출 — 캐시 hit, 호출 안 됨
        await vm.loadTomorrow()
        #expect(await mock.dailyFortuneCallCount == firstCount)
    }
}

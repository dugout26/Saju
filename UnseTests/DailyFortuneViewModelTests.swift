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

    // MARK: - daily-detail 흐름 (loadTodayDetail / loadTomorrowDetail)

    @Test("loadTodayDetail은 snapshot 없으면 즉시 종료, fetch 호출 X")
    func loadTodayDetail_noSnapshotGuard() async {
        let mock = MockAPIClient()
        // fetchDailyDetail이 호출 안 되는 경로이므로 dailyDetailResult 설정 불필요.
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadTodayDetail()
        #expect(vm.todayDetail == nil)
        #expect(!vm.isLoadingDetail)
        #expect(await mock.dailyDetailCallCount == 0)
    }

    @Test("loadTodayDetail 성공 시 todayDetail 설정, isLoadingDetail 해제")
    func loadTodayDetail_success() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        await mock.setDailyDetail(.success("오늘 자세한 풀이"))
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: true)   // snapshot 채움

        await vm.loadTodayDetail()

        #expect(vm.todayDetail == "오늘 자세한 풀이")
        #expect(vm.detailError == nil)
        #expect(!vm.isLoadingDetail)
        #expect(await mock.dailyDetailCallCount == 1)
    }

    @Test("loadTodayDetail 캐시 hit — 이미 채워져 있으면 재호출 X")
    func loadTodayDetail_cacheHit() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        await mock.setDailyDetail(.success("첫 호출"))
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: true)

        await vm.loadTodayDetail()
        let firstCount = await mock.dailyDetailCallCount
        await vm.loadTodayDetail()

        #expect(await mock.dailyDetailCallCount == firstCount)
    }

    @Test("loadTodayDetail 실패 시 detailError 설정, todayDetail nil 유지")
    func loadTodayDetail_failure() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        let err = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "fail"])
        await mock.setDailyDetail(.failure(err))
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: true)

        await vm.loadTodayDetail()

        #expect(vm.todayDetail == nil)
        #expect(vm.detailError != nil)
        #expect(!vm.isLoadingDetail)
    }

    @Test("loadTomorrowDetail 성공 시 tomorrowDetail 설정 (snapshot 가드 X)")
    func loadTomorrowDetail_success() async {
        let mock = MockAPIClient()
        await mock.setDailyDetail(.success("내일 풀이"))
        let vm = DailyFortuneViewModel(client: mock)

        await vm.loadTomorrowDetail()

        #expect(vm.tomorrowDetail == "내일 풀이")
        #expect(vm.detailError == nil)
        #expect(!vm.isLoadingDetail)
        #expect(await mock.dailyDetailCallCount == 1)
    }

    // MARK: - 광고 게이팅 (loadTomorrowGated / loadTodayDetailGated / loadTomorrowDetailGated)

    @Test("loadTomorrowGated premium=true는 광고 호출 X, 즉시 fetch")
    func loadTomorrowGated_premium_skipsAd() async throws {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        let loader = MockRewardedLoader()
        let vm = DailyFortuneViewModel(client: mock, rewardedLoader: loader)

        vm.loadTomorrowGated(isPremium: true)
        let done = try await waitUntil { vm.tomorrowSnapshot != nil }

        #expect(done)
        #expect(loader.loadCallCount == 0)
        #expect(!vm.isLoadingTomorrow)
    }

    @Test("loadTomorrowGated premium=false는 광고 호출 + 캐시 채움")
    func loadTomorrowGated_free_callsLoader() async throws {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        let loader = MockRewardedLoader()
        loader.grantsImmediately = true
        let vm = DailyFortuneViewModel(client: mock, rewardedLoader: loader)

        vm.loadTomorrowGated(isPremium: false)
        let done = try await waitUntil { vm.tomorrowSnapshot != nil }

        #expect(done)
        #expect(loader.loadCallCount == 1)
        #expect(!vm.isLoadingTomorrow)
    }

    @Test("loadTodayDetailGated premium=true는 광고 X, snapshot 있으면 detail 로드")
    func loadTodayDetailGated_premium_skipsAd() async throws {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        await mock.setDailyDetail(.success("today detail"))
        let loader = MockRewardedLoader()
        let vm = DailyFortuneViewModel(client: mock, rewardedLoader: loader)
        await vm.loadFortune(hasSajuProfile: true)

        vm.loadTodayDetailGated(isPremium: true)
        let done = try await waitUntil { vm.todayDetail != nil }

        #expect(done)
        #expect(loader.loadCallCount == 0)
        #expect(vm.todayDetail == "today detail")
    }

    @Test("loadTomorrowDetailGated premium=false는 광고 호출 + tomorrowDetail 설정")
    func loadTomorrowDetailGated_free_callsLoader() async throws {
        let mock = MockAPIClient()
        await mock.setDailyDetail(.success("tomorrow detail"))
        let loader = MockRewardedLoader()
        loader.grantsImmediately = true
        let vm = DailyFortuneViewModel(client: mock, rewardedLoader: loader)

        vm.loadTomorrowDetailGated(isPremium: false)
        let done = try await waitUntil { vm.tomorrowDetail != nil }

        #expect(done)
        #expect(loader.loadCallCount == 1)
        #expect(vm.tomorrowDetail == "tomorrow detail")
    }

    // MARK: - reset (사주 변경 시 캐시 폐기)

    @Test("reset() 호출 시 모든 캐시 nil + isLoading 재설정")
    func reset_clearsAllCaches() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        await mock.setDailyDetail(.success("detail"))
        let vm = DailyFortuneViewModel(client: mock)

        await vm.loadFortune(hasSajuProfile: true)
        await vm.loadTodayDetail()
        await vm.loadTomorrow()
        await vm.loadTomorrowDetail()
        #expect(vm.snapshot != nil)
        #expect(vm.todayDetail != nil)
        #expect(vm.tomorrowSnapshot != nil)
        #expect(vm.tomorrowDetail != nil)

        vm.reset()
        #expect(vm.snapshot == nil)
        #expect(vm.tomorrowSnapshot == nil)
        #expect(vm.todayDetail == nil)
        #expect(vm.tomorrowDetail == nil)
        #expect(vm.loadError == nil)
        #expect(vm.detailError == nil)
        #expect(vm.isLoading)
    }

    @Test("reset 후 loadFortune 다시 호출 → 새 fetch 발생")
    func reset_then_loadFortune_refetches() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture(oneLiner: "첫 운세")))
        let vm = DailyFortuneViewModel(client: mock)
        await vm.loadFortune(hasSajuProfile: true)
        let firstCount = await mock.dailyFortuneCallCount

        vm.reset()
        await mock.setDailyFortune(.success(.fixture(oneLiner: "두번째 운세")))
        await vm.loadFortune(hasSajuProfile: true)

        #expect(await mock.dailyFortuneCallCount == firstCount + 1)
        #expect(vm.snapshot?.oneLiner == "두번째 운세")
    }

    @Test("reset() — Gated 진행 중 호출 시 isLoadingTomorrow/Detail도 false로 초기화")
    func reset_clearsLoadingFlags() async {
        let mock = MockAPIClient()
        await mock.setDailyFortune(.success(.fixture()))
        let loader = MockRewardedLoader()
        loader.grantsImmediately = false   // reward 지연 → isLoadingTomorrow=true 유지
        let vm = DailyFortuneViewModel(client: mock, rewardedLoader: loader)

        vm.loadTomorrowGated(isPremium: false)
        #expect(vm.isLoadingTomorrow)

        vm.reset()

        #expect(!vm.isLoadingTomorrow)
        #expect(!vm.isLoadingDetail)
    }
}

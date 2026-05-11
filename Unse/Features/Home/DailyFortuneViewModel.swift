import Foundation
import Observation
import FirebaseCrashlytics

// 오늘/내일 운세 로딩 상태 + 광고 게이팅 — DailyFortuneView UI 밖으로 분리.
// SwiftUI 의존성 없음 (testable).

@Observable
@MainActor
final class DailyFortuneViewModel {
    var snapshot: DailyFortuneSnapshot?
    var tomorrowSnapshot: DailyFortuneSnapshot?
    var isLoading = true
    var isLoadingTomorrow = false   // 내일 미리보기 중복 클릭 차단
    var loadError: String?

    /// 오늘 자세 풀이 (사용자 #2 형식). nil이면 미로드, 빈 문자열이면 로딩 중.
    var todayDetail: String?
    /// 내일 자세 풀이.
    var tomorrowDetail: String?
    var isLoadingDetail = false
    var detailError: String?

    private let client: any APIClientProtocol
    private let rewardedLoader: any RewardedAdPresenting

    init(
        client: any APIClientProtocol = APIClient.shared,
        rewardedLoader: any RewardedAdPresenting = RewardedAdLoader()
    ) {
        self.client = client
        self.rewardedLoader = rewardedLoader
    }

    /// 사주 정보 변경 후 호출 — 캐시된 운세/풀이를 모두 초기화. 다음 loadFortune이
    /// 새 사주 기준으로 fetch하도록. loading flag도 초기화 (Gated 함수가 영구 차단
    /// 되지 않도록).
    func reset() {
        snapshot = nil
        tomorrowSnapshot = nil
        todayDetail = nil
        tomorrowDetail = nil
        loadError = nil
        detailError = nil
        isLoading = true
        isLoadingTomorrow = false
        isLoadingDetail = false
    }

    /// 오늘의 운세 로드. saju 프로필 없으면 즉시 종료 (loading off).
    func loadFortune(hasSajuProfile: Bool) async {
        guard hasSajuProfile else { isLoading = false; return }
        isLoading = true
        loadError = nil
        let dayPillar = DailyFortuneEngine.dayPillarString()
        do {
            let dto = try await client.fetchDailyFortune(dayPillarOfDate: dayPillar, forDate: nil)
            snapshot = DailyFortuneSnapshot(dto: dto)
        } catch {
            Crashlytics.crashlytics().record(error: error)
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    /// 내일 운세 로드 (캐시되어 있으면 skip).
    func loadTomorrow() async {
        guard tomorrowSnapshot == nil else { return }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayPillar = DailyFortuneEngine.dayPillarString(for: tomorrow)
        if let dto = try? await client.fetchDailyFortune(
            dayPillarOfDate: dayPillar,
            forDate: tomorrow
        ) {
            tomorrowSnapshot = DailyFortuneSnapshot(dto: dto)
        }
    }

    /// 오늘의 자세한 풀이 로드 (사용자 #2 프롬프트 형식). 캐시되어 있으면 skip.
    func loadTodayDetail() async {
        guard todayDetail == nil else { return }
        guard snapshot != nil else { return }   // 사주 프로필 + 오늘 운세 먼저
        isLoadingDetail = true
        detailError = nil
        let dayPillar = DailyFortuneEngine.dayPillarString()
        do {
            let content = try await client.fetchDailyDetail(
                dayPillarOfDate: dayPillar,
                forDate: nil,
                isTomorrow: false
            )
            todayDetail = content
        } catch {
            Crashlytics.crashlytics().record(error: error)
            detailError = error.localizedDescription
        }
        isLoadingDetail = false
    }

    /// 내일의 자세한 풀이 로드. 캐시되어 있으면 skip.
    func loadTomorrowDetail() async {
        guard tomorrowDetail == nil else { return }
        isLoadingDetail = true
        detailError = nil
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayPillar = DailyFortuneEngine.dayPillarString(for: tomorrow)
        do {
            let content = try await client.fetchDailyDetail(
                dayPillarOfDate: dayPillar,
                forDate: tomorrow,
                isTomorrow: true
            )
            tomorrowDetail = content
        } catch {
            Crashlytics.crashlytics().record(error: error)
            detailError = error.localizedDescription
        }
        isLoadingDetail = false
    }

    /// PRO: 즉시 loadTomorrow. 무료: 광고 시청 → reward → loadTomorrow.
    /// load fail / 광고 미수신 시 1.5s fallback. ChatViewModel.sendGated와 동일 패턴.
    /// hasGranted 플래그로 reward + fallback 이중 trigger 방지.
    /// 중복 클릭 차단: tomorrowSnapshot 이미 있거나 진행 중이면 즉시 return.
    func loadTomorrowGated(isPremium: Bool) {
        guard tomorrowSnapshot == nil, !isLoadingTomorrow else { return }
        isLoadingTomorrow = true

        let onDone: @MainActor () -> Void = { [weak self] in
            self?.isLoadingTomorrow = false
        }

        if isPremium {
            Task { await loadTomorrow(); onDone() }
            return
        }

        var hasGranted = false
        let grant: @MainActor () -> Void = { [weak self] in
            guard let self, !hasGranted else { return }
            hasGranted = true
            Task { await self.loadTomorrow(); onDone() }
        }
        rewardedLoader.loadAndShow(unitId: AdsManager.rewardedUnitId) { grant() }
        Task {
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return
            }
            grant()
        }
    }

    /// 오늘 자세 풀이 광고 게이팅. PRO: 즉시. Free: 광고 → reward → loadTodayDetail.
    /// 메모리 cache (todayDetail) hit 시 광고 X — 같은 sheet 재진입 시 즉시.
    func loadTodayDetailGated(isPremium: Bool) {
        guard todayDetail == nil, !isLoadingDetail else { return }
        if isPremium {
            Task { await loadTodayDetail() }
            return
        }
        gatedDetailLoad { [weak self] in
            await self?.loadTodayDetail()
        }
    }

    /// 내일 자세 풀이 광고 게이팅. 같은 패턴.
    func loadTomorrowDetailGated(isPremium: Bool) {
        guard tomorrowDetail == nil, !isLoadingDetail else { return }
        if isPremium {
            Task { await loadTomorrowDetail() }
            return
        }
        gatedDetailLoad { [weak self] in
            await self?.loadTomorrowDetail()
        }
    }

    /// 광고 reward 또는 1.5s fallback 후 detail load 클로저 실행. hasGranted로 이중 trigger 방지.
    private func gatedDetailLoad(_ load: @escaping @Sendable @MainActor () async -> Void) {
        var hasGranted = false
        let grant: @MainActor () -> Void = { @MainActor in
            guard !hasGranted else { return }
            hasGranted = true
            Task { await load() }
        }
        rewardedLoader.loadAndShow(unitId: AdsManager.rewardedUnitId) { grant() }
        Task {
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return
            }
            grant()
        }
    }
}

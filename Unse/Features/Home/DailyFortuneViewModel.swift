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
    var loadError: String?

    /// 오늘 자세 풀이 (사용자 #2 형식). nil이면 미로드, 빈 문자열이면 로딩 중.
    var todayDetail: String?
    /// 내일 자세 풀이.
    var tomorrowDetail: String?
    var isLoadingDetail = false
    var detailError: String?

    private let client: any APIClientProtocol
    private let rewardedLoader = RewardedAdLoader()

    init(client: any APIClientProtocol = APIClient.shared) {
        self.client = client
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
    func loadTomorrowGated(isPremium: Bool) {
        if isPremium {
            Task { await loadTomorrow() }
            return
        }

        var hasGranted = false
        let grant: @MainActor () -> Void = { [weak self] in
            guard let self, !hasGranted else { return }
            hasGranted = true
            Task { await self.loadTomorrow() }
        }
        rewardedLoader.loadAndShow(unitId: AdsManager.rewardedUnitId) { grant() }
        Task {
            // task cancel 시 sleep throw — try?로 묵살하면 if !granted 분기가 즉시 진행되는
            // race가 있어 do/catch return으로 cleanup.
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return
            }
            grant()
        }
    }
}

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

    private let rewardedLoader = RewardedAdLoader()

    /// 오늘의 운세 로드. saju 프로필 없으면 즉시 종료 (loading off).
    func loadFortune(hasSajuProfile: Bool) async {
        guard hasSajuProfile else { isLoading = false; return }
        isLoading = true
        loadError = nil
        let dayPillar = DailyFortuneEngine.dayPillarString()
        do {
            let dto = try await APIClient.shared.fetchDailyFortune(dayPillarOfDate: dayPillar)
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
        if let dto = try? await APIClient.shared.fetchDailyFortune(
            dayPillarOfDate: dayPillar,
            forDate: tomorrow
        ) {
            tomorrowSnapshot = DailyFortuneSnapshot(dto: dto)
        }
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

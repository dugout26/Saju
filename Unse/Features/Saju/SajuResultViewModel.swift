import Foundation
import Observation

// 사주 풀이 stage 1·2 비동기 로딩 상태 — SajuResultView UI 밖으로 분리.
// SwiftUI 의존성 없음 (testable). UI 전용 상태(navigation/sheet)는 View에 잔류.

@Observable
@MainActor
final class SajuResultViewModel {
    var stage1Text: String?
    var stage2Text: String?

    /// stage 1 + 2 풀이 병렬 로딩. 실패는 silent — UI에서 "분석 중..." 그대로 표시.
    /// 첫 진입 시 OnboardingService.prefetchReadings로 캐시되어 있으면 즉시 hit.
    func loadReadings(saju: SajuComputed, nickname: String) async {
        async let s1 = try? await APIClient.shared.fetchSajuReading(stage: 1, saju: saju, nickname: nickname)
        async let s2 = try? await APIClient.shared.fetchSajuReading(stage: 2, saju: saju, nickname: nickname)
        let (r1, r2) = await (s1, s2)
        if let r1 { stage1Text = r1 }
        if let r2 { stage2Text = r2 }
    }
}

import Foundation
@testable import Unse

/// 광고 SDK 의존 없는 stub. 테스트에서 reward callback timing을 결정적으로 제어.
@MainActor
final class MockRewardedLoader: RewardedAdPresenting {
    /// loadAndShow 호출 시 즉시 onReward를 호출할지 (default: true).
    var grantsImmediately: Bool = true
    private(set) var loadCallCount = 0
    private(set) var lastUnitId: String?

    func loadAndShow(unitId: String, onReward: @escaping () -> Void) {
        loadCallCount += 1
        lastUnitId = unitId
        if grantsImmediately {
            onReward()
        }
    }
}

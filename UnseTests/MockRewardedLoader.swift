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

/// 조건이 참이 될 때까지 짧게 폴링 (Task.yield + 10ms sleep). 비결정적 시간 의존 제거.
/// timeoutMs 안에 만족 안 되면 false. 기본 timeout 500ms — CI 부하 여유.
@MainActor
func waitUntil(timeoutMs: Int = 500, _ condition: () -> Bool) async throws -> Bool {
    let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000.0)
    while Date() < deadline {
        if condition() { return true }
        try await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}

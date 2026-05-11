import Foundation
import Observation

/// 평생 흐름(대운) 화면 ViewModel — daeWoonJSON decode + UI 상태.
/// View는 binding + display만, 도메인 변환은 vm에 위임.
@Observable
@MainActor
final class TimelineViewModel {

    let user: UserProfile?

    var daeWoon: [DaeWoon] = []
    var selectedDaeWoon: DaeWoon?
    var showPaywall = false

    init(user: UserProfile?) {
        self.user = user
        loadDaeWoon()
    }

    /// SajuProfile.daeWoonJSON을 [DaeWoon]로 decode. 실패 시 빈 배열.
    /// pure decoding이라 nonisolated로 분리해 테스트 가능.
    private func loadDaeWoon() {
        daeWoon = Self.decodeDaeWoon(json: user?.sajuProfile?.daeWoonJSON)
    }

    /// daeWoonJSON 문자열 → [DaeWoon] 배열. nil이거나 깨진 JSON이면 빈 배열.
    /// nonisolated — 테스트에서 직접 호출 가능.
    nonisolated static func decodeDaeWoon(json: String?) -> [DaeWoon] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([DaeWoon].self, from: data)) ?? []
    }

    /// 출생연도 기준 현재 만 나이 (해당 사주 프로필 기준).
    var currentAge: Int {
        guard let profile = user?.sajuProfile else { return 30 }
        return Calendar.current.component(.year, from: Date()) - profile.birthYear
    }
}

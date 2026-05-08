import Foundation

// MARK: - APIClientProtocol
//
// ViewModel/Service가 actor singleton APIClient.shared 직접 참조 대신 protocol을 받도록 분리.
// 테스트에서 MockAPIClient 주입 → 실제 네트워크 없이 ViewModel async 흐름 검증.
//
// Phase 3-3 — CodeRabbit 평가의 테스트 점수 (38 → 50 → ?) 향상 목표.

protocol APIClientProtocol: Sendable {
    func fetchDailyFortune(dayPillarOfDate: String, forDate: Date?) async throws -> DailyFortuneDTO
    func fetchSajuReading(stage: Int, saju: SajuComputed, nickname: String) async throws -> String
    func fetchAppConfig() async throws -> AppConfigDTO
    func registerPushToken(_ token: String, userId: String) async throws
    func chatStream(messages: [[String: String]]) async -> AsyncThrowingStream<String, Error>
}

extension APIClient: APIClientProtocol {}

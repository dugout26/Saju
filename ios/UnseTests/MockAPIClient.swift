import Foundation
@testable import Unse

// MARK: - MockAPIClient
//
// APIClientProtocol 테스트용 stub. 미리 결과를 set한 후 ViewModel 호출 → 검증.
// 모든 메서드는 미설정 시 fatalError (의도된 미사용 검증).

actor MockAPIClient: APIClientProtocol {
    var dailyFortuneResult: Result<DailyFortuneDTO, Error>?
    var dailyDetailResult: Result<String, Error>?
    var sajuReadingResult: Result<String, Error>?
    var appConfigResult: Result<AppConfigDTO, Error>?
    var registerPushTokenResult: Result<Void, Error>?
    var chatStreamChunks: [String] = []
    var chatStreamError: Error?

    var dailyFortuneCallCount = 0
    var dailyDetailCallCount = 0
    var sajuReadingCallCount = 0

    func setDailyFortune(_ result: Result<DailyFortuneDTO, Error>) {
        dailyFortuneResult = result
    }

    func setDailyDetail(_ result: Result<String, Error>) {
        dailyDetailResult = result
    }

    func setSajuReading(_ result: Result<String, Error>) {
        sajuReadingResult = result
    }

    func setChatStream(chunks: [String], error: Error? = nil) {
        chatStreamChunks = chunks
        chatStreamError = error
    }

    func fetchDailyFortune(dayPillarOfDate: String, forDate: Date?) async throws -> DailyFortuneDTO {
        dailyFortuneCallCount += 1
        guard let result = dailyFortuneResult else {
            throw NSError(domain: "MockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "dailyFortuneResult 미설정"])
        }
        return try result.get()
    }

    func fetchDailyDetail(dayPillarOfDate: String, forDate: Date?, isTomorrow: Bool) async throws -> String {
        dailyDetailCallCount += 1
        guard let result = dailyDetailResult else {
            throw NSError(domain: "MockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "dailyDetailResult 미설정"])
        }
        return try result.get()
    }

    func fetchSajuReading(stage: Int, saju: SajuComputed, nickname: String) async throws -> String {
        sajuReadingCallCount += 1
        guard let result = sajuReadingResult else {
            throw NSError(domain: "MockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "sajuReadingResult 미설정"])
        }
        return try result.get()
    }

    func fetchAppConfig() async throws -> AppConfigDTO {
        guard let result = appConfigResult else {
            throw NSError(domain: "MockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "appConfigResult 미설정"])
        }
        return try result.get()
    }

    func registerPushToken(_ token: String, userId: String) async throws {
        guard let result = registerPushTokenResult else {
            throw NSError(domain: "MockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "registerPushTokenResult 미설정"])
        }
        try result.get()
    }

    func chatStream(messages: [[String: String]], today: String, dayPillarOfDate: String) async -> AsyncThrowingStream<String, Error> {
        let chunks = chatStreamChunks
        let error = chatStreamError
        return AsyncThrowingStream { continuation in
            for chunk in chunks {
                continuation.yield(chunk)
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}

// MARK: - DailyFortuneDTO test fixture

extension DailyFortuneDTO {
    static func fixture(oneLiner: String = "오늘은 평온한 하루") -> DailyFortuneDTO {
        DailyFortuneDTO(
            date: "2026-05-08",
            day_pillar_of_date: "庚午",
            one_liner: oneLiner,
            lucky_color_primary: "#C9B8F0",
            lucky_color_secondary: nil,
            lucky_color_name: "라벤더",
            lucky_color_theme: "lavender",
            lucky_direction: "동쪽",
            lucky_time_start: "15:00:00",
            lucky_time_end: "17:00:00",
            lucky_time_label: "申時 (15-17시)",
            lucky_numbers: [3, 7, 21],
            avoid: "성급한 결정"
        )
    }
}

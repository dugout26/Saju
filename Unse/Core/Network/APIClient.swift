import Foundation
import Supabase

// MARK: - API Client
// All Claude/Anthropic calls go through the server-side Edge Function.
// The API key is NEVER stored on device.

actor APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared

    private nonisolated static let anonKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }()

    // MARK: - Daily Fortune (LLM이 색·방향·시간·숫자·한줄·피해야할것 모두 생성)
    //
    // 클라이언트는 오늘 일진(day_pillar_of_date)만 계산해서 전송.
    // Edge Function이 자평명리 분석으로 매일 다른 결과 생성 + daily_fortunes 캐싱.

    func fetchDailyFortune(dayPillarOfDate: String, forDate: Date? = nil) async throws -> DailyFortuneDTO {
        struct Body: Encodable {
            let day_pillar_of_date: String
            let for_date: String?
        }
        let dateStr: String? = forDate.map {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withFullDate]
            return f.string(from: $0)
        }
        var request = try await makeRequest(endpoint: .dailyFortune)
        request.httpBody = try JSONEncoder().encode(Body(
            day_pillar_of_date: dayPillarOfDate,
            for_date: dateStr
        ))
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(DailyFortuneDTO.self, from: data)
    }

    // MARK: - Chat (Server-Sent Events streaming)

    func chatStream(messages: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = try await makeRequest(endpoint: .chat)
                    let body = ChatRequestBody(messages: messages)
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw APIError.badStatus
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        if let delta = parseSSEDelta(payload) {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Saju Reading (단계별 풀이)

    func fetchSajuReading(stage: Int, saju: SajuComputed, nickname: String) async throws -> String {
        #if DEBUG
        if Self.isMockMode {
            return Self.mockSajuReading(stage: stage, saju: saju, nickname: nickname)
        }
        #endif
        var request = try await makeRequest(endpoint: .sajuReading)
        request.httpBody = try JSONEncoder().encode(["stage": stage])
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(SajuReadingDTO.self, from: data).content
    }

    // MARK: - App Config (강제 업데이트 + 스토어 URL)

    func fetchAppConfig() async throws -> AppConfigDTO {
        let row: AppConfigDTO = try await SupabaseManager.shared
            .from("app_config")
            .select()
            .eq("id", value: 1)
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Push Token Registration

    func registerPushToken(_ token: String, userId: String) async throws {
        var request = try await makeRequest(endpoint: .registerPushToken)
        request.httpBody = try JSONEncoder().encode(["token": token, "userId": userId])
        _ = try await session.data(for: request)
    }

    // MARK: - Helpers

    /// Supabase Edge Function 표준 헤더 (apikey + Authorization).
    /// 로그인 상태면 user JWT, 아니면 anon key.
    private func makeRequest(endpoint: Endpoint) async throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.anonKey, forHTTPHeaderField: "apikey")
        let bearer = (try? await SupabaseManager.shared.auth.session.accessToken) ?? Self.anonKey
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        return request
    }

    private func parseSSEDelta(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else { return nil }
        return content
    }

    // MARK: - Mock (DEBUG only) — Phase B에서 baseURL이 진짜 Supabase로 바뀌면 자동 비활성

    #if DEBUG
    nonisolated static var isMockMode: Bool {
        Endpoint.base.absoluteString.contains("placeholder.invalid")
    }

    nonisolated static func mockSajuReading(stage: Int, saju: SajuComputed, nickname: String) -> String {
        let day = saju.dayMaster
        let dom = saju.dominantElement
        switch stage {
        case 1:
            return "\(nickname)님은 \(day.character)(\(day.korean)) 일간으로, \(dom.rawValue)(\(dom.korean)) 기운이 두드러진 사주로 해석됩니다."
        case 2:
            return """
            \(day.character) 일간은 차분함과 결단력이 함께 흐르는 성향으로 풀이됩니다.

            오행 균형에서 \(dom.rawValue) 기운이 두드러져, 이 영역에서 강점이 자연스럽게 드러나는 흐름으로 해석됩니다.
            """
        default:
            return "\(stage)단계 풀이는 준비 중입니다."
        }
    }
    #endif
}

// MARK: - DTOs

struct DailyFortuneDTO: Decodable {
    let date: String
    let day_pillar_of_date: String
    let one_liner: String
    let lucky_color_primary: String      // hex
    let lucky_color_secondary: String?   // 색 이름 (서버 호환)
    let lucky_color_name: String?        // 색 이름 (신규)
    let lucky_color_theme: String?       // "lavender|peach|mint|cream"
    let lucky_direction: String
    let lucky_time_start: String         // "HH:MM:SS"
    let lucky_time_end: String
    let lucky_time_label: String?
    let lucky_numbers: [Int]
    let avoid: String
}

struct ChatRequestBody: Encodable {
    let messages: [[String: String]]
}

struct SajuReadingDTO: Decodable {
    let content: String
}

struct AppConfigDTO: Decodable, Sendable {
    let min_ios_version: String
    let min_android_version: String
    let app_store_url: String?
    let play_store_url: String?
    let force_update_message: String

    /// Bundle.main 의 CFBundleShortVersionString이 min_ios_version 보다 낮은지.
    func requiresForceUpdate() -> Bool {
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        return current.compare(min_ios_version, options: .numeric) == .orderedAscending
    }
}

enum APIError: LocalizedError {
    case badStatus
    var errorDescription: String? { "서버 오류가 발생했어요. 잠시 후 다시 시도해주세요." }
}

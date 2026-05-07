import Foundation

// MARK: - API Client
// All Claude/Anthropic calls go through the server-side Edge Function.
// The API key is NEVER stored on device.

actor APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared
    private var authToken: String? = nil   // set after login

    func setAuthToken(_ token: String) {
        authToken = token
    }

    // MARK: - Daily Fortune

    func fetchDailyFortune(userId: String) async throws -> DailyFortuneDTO {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let date = fmt.string(from: Date())
        let request = try makeRequest(endpoint: .dailyFortune(userId: userId, date: date))
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(DailyFortuneDTO.self, from: data)
    }

    // MARK: - Chat (Server-Sent Events streaming)

    func chatStream(messages: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = try makeRequest(endpoint: .chat)
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

    func fetchSajuReading(stage: Int, saju: SajuComputed, nickname: String, userId: String) async throws -> String {
        #if DEBUG
        if Self.isMockMode {
            return Self.mockSajuReading(stage: stage, saju: saju, nickname: nickname)
        }
        #endif
        let request = try makeRequest(endpoint: .sajuReading(userId: userId, stage: stage))
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(SajuReadingDTO.self, from: data).content
    }

    // MARK: - Push Token Registration

    func registerPushToken(_ token: String, userId: String) async throws {
        var request = try makeRequest(endpoint: .registerPushToken)
        request.httpBody = try JSONEncoder().encode(["token": token, "userId": userId])
        _ = try await session.data(for: request)
    }

    // MARK: - Helpers

    private func makeRequest(endpoint: Endpoint) throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
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
        Endpoint.base.absoluteString.contains("api.unse.kr")
    }

    nonisolated static func mockSajuReading(stage: Int, saju: SajuComputed, nickname: String) -> String {
        let day = saju.dayMaster
        let dom = saju.dominantElement
        switch stage {
        case 1:
            return "\(nickname)님은 \(day.character)(\(day.korean)) 일간으로, \(dom.rawValue)(\(dom.korean)) 기운이 두드러진 사주로 해석됩니다."
        case 2:
            return "\(day.character) 일간은 차분함과 결단력이 함께 흐르는 성향으로 풀이됩니다.\n\n오행 균형에서 \(dom.rawValue) 기운이 두드러져, 이 영역에서 강점이 자연스럽게 드러나는 흐름으로 해석됩니다."
        default:
            return "\(stage)단계 풀이는 준비 중입니다."
        }
    }
    #endif
}

// MARK: - DTOs

struct DailyFortuneDTO: Decodable {
    let oneLiner: String
    let luckyColorHex: String
    let luckyColorTheme: String
    let luckyDirection: String
    let luckyTimeStart: String
    let luckyTimeEnd: String
    let luckyNumbers: [Int]
    let avoid: String
}

struct ChatRequestBody: Encodable {
    let messages: [[String: String]]
}

struct SajuReadingDTO: Decodable {
    let content: String
}

enum APIError: LocalizedError {
    case badStatus
    var errorDescription: String? { "서버 오류가 발생했어요. 잠시 후 다시 시도해주세요." }
}

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

    func chatStream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = try makeRequest(endpoint: .chat)
                    let body = ChatRequestBody(messages: messages.map {
                        ["role": $0.role, "content": $0.content]
                    })
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

enum APIError: LocalizedError {
    case badStatus
    var errorDescription: String? { "서버 오류가 발생했어요. 잠시 후 다시 시도해주세요." }
}

import Foundation

enum Endpoint {
    static let base = URL(string: "https://api.unse.kr/v1")!

    case dailyFortune(userId: String, date: String)
    case sajuReading(userId: String, stage: Int)
    case chat
    case registerPushToken

    var url: URL {
        switch self {
        case .dailyFortune(let uid, let date):
            return Self.base.appending(path: "/fortune/\(uid)/\(date)")
        case .sajuReading(let uid, let stage):
            return Self.base.appending(path: "/saju/\(uid)/stage/\(stage)")
        case .chat:
            return Self.base.appending(path: "/chat")
        case .registerPushToken:
            return Self.base.appending(path: "/push/register")
        }
    }

    var method: String {
        switch self {
        case .dailyFortune, .sajuReading: return "GET"
        case .chat, .registerPushToken:   return "POST"
        }
    }
}

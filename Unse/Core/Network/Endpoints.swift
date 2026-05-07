import Foundation

enum Endpoint {
    /// Supabase project URL. Info.plist의 SUPABASE_URL에서 읽음.
    /// Phase B 셋업 전엔 빈 문자열이고 APIClient는 mock으로 동작.
    static let base: URL = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        return URL(string: raw.isEmpty ? "https://placeholder.invalid" : raw)!
    }()

    case dailyFortune
    case sajuReading
    case chat
    case registerPushToken

    var url: URL {
        switch self {
        case .dailyFortune:     return Self.base.appending(path: "/functions/v1/daily-fortune")
        case .sajuReading:      return Self.base.appending(path: "/functions/v1/saju-reading")
        case .chat:             return Self.base.appending(path: "/functions/v1/chat")
        case .registerPushToken: return Self.base.appending(path: "/functions/v1/register-push-token")
        }
    }

    var method: String { "POST" }
}

import Foundation
import Supabase

/// 앱 전역 Supabase client. URL/anon key는 Info.plist에서 읽음.
enum SupabaseManager {
    static let shared: SupabaseClient = {
        let urlStr = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        let url = URL(string: urlStr.isEmpty ? "https://placeholder.invalid" : urlStr)!
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()
}

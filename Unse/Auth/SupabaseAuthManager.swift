import Foundation
@preconcurrency import Supabase
import FirebaseCrashlytics
import FirebaseAnalytics

/// Apple/Kakao 로그인을 Supabase Auth에 연결.
/// 로그인 성공 시 public.users row를 upsert (auth.users.id = users.id).
@MainActor
enum SupabaseAuthManager {

    /// Apple Sign in → Supabase 교환 → users row upsert. 반환: Supabase user id.
    /// nickname을 명시 전달하면 Apple fullName보다 우선 (온보딩에서 입력한 값 사용).
    static func signInWithApple(nickname: String? = nil) async throws -> UUID {
        let apple = try await AppleAuthManager.shared.signIn()
        guard !apple.idToken.isEmpty, !apple.rawNonce.isEmpty else {
            throw AuthError.invalidCredential
        }

        let session = try await SupabaseManager.shared.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: apple.idToken,
                nonce: apple.rawNonce
            )
        )

        let resolvedNickname = nickname?.isEmpty == false ? nickname!
            : (apple.fullName.isEmpty ? "사용자" : apple.fullName)

        try await upsertUser(
            id: session.user.id,
            nickname: resolvedNickname,
            authProvider: "apple"
        )

        // Crashlytics에 user 식별자 연결 (PII 없음 — Supabase UUID만)
        Crashlytics.crashlytics().setUserID(session.user.id.uuidString)
        // Analytics: 표준 login 이벤트 (Apple).
        Analytics.logEvent(AnalyticsEventLogin, parameters: [AnalyticsParameterMethod: "apple"])

        return session.user.id
    }

    /// Kakao OAuth → Edge Function (kakao-auth) → magic-link token_hash → verifyOTP.
    /// nickname 명시 전달 시 카카오 nickname보다 우선.
    static func signInWithKakao(nickname: String? = nil) async throws -> UUID {
        let kakao = try await KakaoAuthManager.shared.signIn()

        // Edge Function 호출 → token_hash 획득
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        var request = URLRequest(url: Endpoint.kakaoAuth.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        struct Body: Encodable { let access_token: String }
        request.httpBody = try JSONEncoder().encode(Body(access_token: kakao.accessToken))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.invalidCredential
        }
        struct TokenResponse: Decodable { let token_hash: String; let email: String }
        let resp = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Supabase verifyOTP → 표준 세션 획득
        let auth = try await SupabaseManager.shared.auth.verifyOTP(
            tokenHash: resp.token_hash,
            type: .magiclink
        )
        guard let session = auth.session else {
            throw AuthError.invalidCredential
        }

        let resolvedNickname = nickname?.isEmpty == false ? nickname!
            : (kakao.nickname.isEmpty ? "사용자" : kakao.nickname)

        try await upsertUser(
            id: session.user.id,
            nickname: resolvedNickname,
            authProvider: "kakao"
        )

        Crashlytics.crashlytics().setUserID(session.user.id.uuidString)
        Analytics.logEvent(AnalyticsEventLogin, parameters: [AnalyticsParameterMethod: "kakao"])

        return session.user.id
    }

    /// 만세력 계산 결과를 saju_profiles에 upsert.
    static func upsertSajuProfile(input: BirthInput, saju: SajuComputed, daeWoon: [DaeWoon]) async throws {
        struct Row: Encodable {
            let user_id: UUID
            let birth_calendar: String
            let birth_year: Int
            let birth_month: Int
            let birth_day: Int
            let birth_hour: Int?
            let birth_minute: Int?
            let gender: String
            let birth_place: String
            let year_pillar: String
            let month_pillar: String
            let day_pillar: String
            let hour_pillar: String?
            let day_master: String
            let five_elements_dist: [String: Int]
            let dae_woon: [DaeWoonDTO]
        }
        struct DaeWoonDTO: Encodable {
            let start_age: Int
            let pillar: String
            let start_year: Int
        }

        guard let userId = try? await SupabaseManager.shared.auth.session.user.id else {
            throw AuthError.invalidCredential
        }

        let elements = Dictionary(uniqueKeysWithValues: saju.fiveElements.map { ($0.key.rawValue, $0.value) })

        let row = Row(
            user_id: userId,
            birth_calendar: input.calendar.rawValue == "양력" ? "solar" : "lunar",
            birth_year: input.year,
            birth_month: input.month,
            birth_day: input.day,
            birth_hour: input.hour,
            birth_minute: input.minute,
            gender: input.gender == .male ? "male" : "female",
            birth_place: "서울",
            year_pillar: saju.year.characters,
            month_pillar: saju.month.characters,
            day_pillar: saju.day.characters,
            hour_pillar: saju.hour?.characters,
            day_master: saju.dayMaster.character,
            five_elements_dist: elements,
            dae_woon: daeWoon.map { DaeWoonDTO(start_age: $0.startAge, pillar: $0.pillar.characters, start_year: $0.startYear) }
        )

        try await SupabaseManager.shared
            .from("saju_profiles")
            .upsert(row, onConflict: "user_id")
            .execute()
    }

    /// 현재 세션 (앱 시작 시 자동 복원). nil이면 로그인 안 된 상태.
    static var currentUserId: UUID? {
        get async {
            try? await SupabaseManager.shared.auth.session.user.id
        }
    }

    static func signOut() async throws {
        try await SupabaseManager.shared.auth.signOut()
    }

    /// 재로그인 시 서버에 이미 저장된 사주 프로필 복원용.
    /// saju_profiles 행이 없으면(신규 회원가입 흐름) nil → 호출자가 BirthInfoView 진입.
    /// 있으면 BirthInput + push 설정 반환 → Manse 재계산해 로컬 SwiftData 복원.
    struct ExistingProfileSnapshot {
        let nickname: String
        let authProvider: String
        let pushTime: Date            // KST "HH:mm:ss" → today's Date
        let pushEnabled: Bool
        let input: BirthInput
    }

    static func fetchExistingProfile() async throws -> ExistingProfileSnapshot? {
        guard let userId = try? await SupabaseManager.shared.auth.session.user.id else {
            throw AuthError.invalidCredential
        }

        struct SajuRow: Decodable {
            let birth_calendar: String
            let birth_year: Int
            let birth_month: Int
            let birth_day: Int
            let birth_hour: Int?
            let birth_minute: Int?
            let gender: String
        }
        let sajuResp = try await SupabaseManager.shared
            .from("saju_profiles")
            .select("birth_calendar, birth_year, birth_month, birth_day, birth_hour, birth_minute, gender")
            .eq("user_id", value: userId)
            .execute()
        let sajuRows = try JSONDecoder().decode([SajuRow].self, from: sajuResp.data)
        guard let saju = sajuRows.first else { return nil }   // 신규 회원가입 흐름

        struct UserRow: Decodable {
            let nickname: String
            let auth_provider: String
            let push_time: String
            let push_enabled: Bool
        }
        let userResp = try await SupabaseManager.shared
            .from("users")
            .select("nickname, auth_provider, push_time, push_enabled")
            .eq("id", value: userId)
            .execute()
        let userRows = try JSONDecoder().decode([UserRow].self, from: userResp.data)
        guard let user = userRows.first else { return nil }

        var input = BirthInput()
        input.calendar = saju.birth_calendar == "lunar" ? .lunar : .solar
        input.year = saju.birth_year
        input.month = saju.birth_month
        input.day = saju.birth_day
        input.hour = saju.birth_hour
        input.minute = saju.birth_minute
        input.gender = saju.gender == "male" ? .male : .female
        input.nickname = user.nickname

        return ExistingProfileSnapshot(
            nickname: user.nickname,
            authProvider: user.auth_provider,
            pushTime: Self.parsePushTimeKST(user.push_time),
            pushEnabled: user.push_enabled,
            input: input
        )
    }

    /// PostgreSQL `time` ("HH:mm:ss" KST) → 오늘 날짜의 해당 시각 Date.
    /// 서버 cron이 KST 기준 비교라 복원 시점에도 KST timezone으로 매핑.
    nonisolated static func parsePushTimeKST(_ str: String) -> Date {
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else {
            return Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone(secondsFromGMT: 9 * 3600)!
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = parts[0]
        comps.minute = parts[1]
        return cal.date(from: comps) ?? Date()
    }

    /// 출생정보 입력 후 닉네임만 update (Apple fullName 대신).
    static func updateNickname(_ nickname: String) async throws {
        guard let userId = try? await SupabaseManager.shared.auth.session.user.id else {
            throw AuthError.invalidCredential
        }
        struct Update: Encodable { let nickname: String }
        try await SupabaseManager.shared
            .from("users")
            .update(Update(nickname: nickname))
            .eq("id", value: userId)
            .execute()
    }

    /// 푸시 알림 시간 서버 동기화. `Date` → KST `"HH:mm:ss"` 변환.
    /// 서버 cron이 매 30분 KST 기준으로 user.push_time 매칭해 발송하므로 KST 변환 필수.
    static func updatePushTime(_ time: Date) async throws {
        guard let userId = try? await SupabaseManager.shared.auth.session.user.id else {
            throw AuthError.invalidCredential
        }
        struct Update: Encodable { let push_time: String }
        try await SupabaseManager.shared
            .from("users")
            .update(Update(push_time: Self.kstTimeString(from: time)))
            .eq("id", value: userId)
            .execute()
    }

    /// 푸시 on/off 서버 동기화. off면 cron 발송 대상 제외.
    static func updatePushEnabled(_ enabled: Bool) async throws {
        guard let userId = try? await SupabaseManager.shared.auth.session.user.id else {
            throw AuthError.invalidCredential
        }
        struct Update: Encodable { let push_enabled: Bool }
        try await SupabaseManager.shared
            .from("users")
            .update(Update(push_enabled: enabled))
            .eq("id", value: userId)
            .execute()
    }

    /// `Date` → KST 24h `"HH:mm:ss"`. PostgreSQL `time` 컬럼 포맷.
    /// nonisolated — 테스트에서 직접 호출 가능.
    nonisolated static func kstTimeString(from date: Date) -> String {
        kstTimeFormatter.string(from: date)
    }

    /// 호출마다 DateFormatter 생성 비용을 피하려 static let으로 캐싱. read-only 사용은 thread-safe.
    private nonisolated static let kstTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone(secondsFromGMT: 9 * 3600)!
        return f
    }()

    // MARK: - Helpers

    private static func upsertUser(id: UUID, nickname: String, authProvider: String) async throws {
        struct Row: Encodable {
            let id: UUID
            let nickname: String
            let auth_provider: String
            let last_active_at: Date
        }
        try await SupabaseManager.shared
            .from("users")
            .upsert(Row(
                id: id,
                nickname: nickname,
                auth_provider: authProvider,
                last_active_at: Date()
            ), onConflict: "id")
            .execute()
    }
}

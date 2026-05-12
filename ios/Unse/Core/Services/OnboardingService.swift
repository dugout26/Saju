import Foundation
import SwiftData

// MARK: - OnboardingService
//
// onboarding 마지막 단계의 부수 효과 (Supabase 동기화 + SwiftData 생성 + 푸시 권한 요청)를
// View 밖으로 분리. AnalyzingView는 UI만 담당하고 이 service에 위임.
//
// MV(VM) 정공 — View → ViewModel → Service → APIClient/SwiftData.

@MainActor
enum OnboardingService {

    /// onboarding 흐름 마지막에 호출. 실패 시 throw — 호출자가 사용자에게 alert.
    /// 1. Supabase users.nickname update
    /// 2. Supabase saju_profiles upsert
    /// 3. SwiftData UserProfile + SajuProfile insert (provider는 session metadata로 동적)
    /// 4. 푸시 권한 요청 (실패해도 throw X — 사용자가 거부할 수 있음)
    static func completeSignup(
        input: BirthInput,
        saju: SajuComputed,
        daeWoon: [DaeWoon],
        modelContext: ModelContext
    ) async throws {
        try await SupabaseAuthManager.updateNickname(input.nickname)
        try await SupabaseAuthManager.upsertSajuProfile(
            input: input, saju: saju, daeWoon: daeWoon
        )

        // provider 판별 — 세션 조회 실패 시 fallback "apple"이 아니라 throw.
        // 카카오 사용자가 잘못 저장되는 것 방지.
        let session = try await SupabaseManager.shared.auth.session
        let isKakao = session.user.userMetadata["kakao_id"] != nil
        let authProvider = isKakao ? "kakao" : "apple"

        try saveLocalProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            authProvider: authProvider, modelContext: modelContext
        )

        // 푸시 권한은 거부돼도 onboarding은 성공으로 처리
        _ = await PushManager.shared.requestPermission()
    }

    /// completeSignup의 SwiftData 저장 부분만 분리 — 외부 의존(Supabase / Push) 없이
    /// 단위 테스트 가능. UserProfile + SajuProfile 생성 후 insert + save.
    static func saveLocalProfile(
        input: BirthInput,
        saju: SajuComputed,
        daeWoon: [DaeWoon],
        authProvider: String,
        modelContext: ModelContext
    ) throws {
        let user = UserProfile(nickname: input.nickname, authProvider: authProvider)
        let profile = SajuProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            displayName: input.nickname, relation: "본인"
        )
        user.sajuProfile = profile
        modelContext.insert(user)
        try modelContext.save()
    }

    /// 재로그인 시 서버에 이미 있는 프로필을 로컬 SwiftData에 복원.
    /// Manse는 deterministic이라 BirthInput만 있으면 pillar/daeWoon 재계산 가능 — 직렬화 우회.
    /// 호출자: LoginView signIn 성공 path. snapshot nil이면 호출 안 함 (신규 회원가입).
    static func restoreLocalProfile(
        snapshot: SupabaseAuthManager.ExistingProfileSnapshot,
        modelContext: ModelContext
    ) throws {
        let result = Manse.calculate(
            year: snapshot.input.year,
            month: snapshot.input.month,
            day: snapshot.input.day,
            hour: snapshot.input.hour,
            gender: snapshot.input.gender
        )
        let user = UserProfile(
            nickname: snapshot.nickname,
            authProvider: snapshot.authProvider,
            pushTime: snapshot.pushTime,
            pushEnabled: snapshot.pushEnabled
        )
        let profile = SajuProfile(
            input: snapshot.input, saju: result.saju, daeWoon: result.daeWoon,
            displayName: snapshot.nickname, relation: "본인"
        )
        user.sajuProfile = profile
        modelContext.insert(user)
        try modelContext.save()
    }

    /// stage 1·2 풀이 background prefetch. 결과 무시 — saju_readings에 캐시되므로
    /// SajuResultView 진입 시 자동 hit. 호출 실패 무시.
    /// client 파라미터는 테스트에서 mock 주입용.
    static func prefetchReadings(
        saju: SajuComputed,
        nickname: String,
        client: any APIClientProtocol = APIClient.shared
    ) {
        Task.detached {
            async let s1 = client.fetchSajuReading(stage: 1, saju: saju, nickname: nickname)
            async let s2 = client.fetchSajuReading(stage: 2, saju: saju, nickname: nickname)
            _ = try? await (s1, s2)
        }
    }
}

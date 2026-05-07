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

        // provider 판별 — kakao_id가 있으면 카카오, 아니면 apple
        let session = try? await SupabaseManager.shared.auth.session
        let isKakao = (session?.user.userMetadata["kakao_id"]) != nil
        let authProvider = isKakao ? "kakao" : "apple"

        let user = UserProfile(nickname: input.nickname, authProvider: authProvider)
        let profile = SajuProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            displayName: input.nickname, relation: "본인"
        )
        user.sajuProfile = profile
        modelContext.insert(user)
        try modelContext.save()

        // 푸시 권한은 거부돼도 onboarding은 성공으로 처리
        _ = await PushManager.shared.requestPermission()
    }

    /// stage 1·2 풀이 background prefetch. 결과 무시 — saju_readings에 캐시되므로
    /// SajuResultView 진입 시 자동 hit. 호출 실패 무시.
    static func prefetchReadings(saju: SajuComputed, nickname: String) {
        Task.detached {
            async let s1 = APIClient.shared.fetchSajuReading(stage: 1, saju: saju, nickname: nickname)
            async let s2 = APIClient.shared.fetchSajuReading(stage: 2, saju: saju, nickname: nickname)
            _ = try? await (s1, s2)
        }
    }
}

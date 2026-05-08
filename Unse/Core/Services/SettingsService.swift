import Foundation
import SwiftData

// MARK: - SettingsService
//
// 설정 화면의 부수 효과 (push 토글/시간 저장 + 계정 삭제 + 로그아웃)를 View 밖으로 분리.
// SettingsView는 UI/binding/alert만 담당, 비즈니스 효과는 모두 Service 위임.
//
// MV(VM) 정공 — View → Service → SwiftData/Push/Supabase.

@MainActor
enum SettingsService {

    /// 푸시 on/off 저장. on이면 권한 요청. 실패는 throw — 호출자가 alert.
    static func updatePushEnabled(
        _ enabled: Bool,
        user: UserProfile,
        modelContext: ModelContext
    ) throws {
        user.pushEnabled = enabled
        try modelContext.save()
        if enabled {
            Task { _ = await PushManager.shared.requestPermission() }
        }
    }

    /// 푸시 시간 저장 + 알림 재예약. 저장 실패는 throw, 예약은 best-effort.
    static func updatePushTime(
        _ time: Date,
        user: UserProfile,
        nickname: String,
        modelContext: ModelContext
    ) throws {
        user.pushTime = time
        try modelContext.save()
        Task { await PushManager.shared.scheduleDailyFortunePush(at: time, nickname: nickname) }
    }

    /// 계정 삭제 — 로컬 SwiftData만. (Supabase 측 user row 삭제는 admin function 별도)
    static func deleteAccount(
        user: UserProfile,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(user)
        try modelContext.save()
    }

    /// 로그아웃 — Supabase signOut 성공 후에만 로컬 user 삭제.
    /// 부분 실패로 세션 갈리는 거 방지 — signOut 실패 시 로컬 user 보존하고 throw.
    static func logout(
        user: UserProfile,
        modelContext: ModelContext
    ) async throws {
        try await SupabaseAuthManager.signOut()
        modelContext.delete(user)
        try modelContext.save()
    }
}

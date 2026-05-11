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

    /// 푸시 on/off 저장. on이면 권한 요청. 로컬 저장 실패는 throw — 호출자가 alert.
    /// 서버 동기화 실패는 best-effort (로컬 ON/OFF는 반영, 서버 cron이 다음 30분 윈도우에 재시도).
    static func updatePushEnabled(
        _ enabled: Bool,
        user: UserProfile,
        modelContext: ModelContext
    ) async throws {
        user.pushEnabled = enabled
        try modelContext.save()
        if enabled {
            Task { _ = await PushManager.shared.requestPermission() }
        }
        try await SupabaseAuthManager.updatePushEnabled(enabled)
    }

    /// 푸시 시간 저장 + 로컬 알림 재예약 + 서버 cron용 push_time 동기화.
    /// 서버 동기화 누락 시 cron이 기본값 07:30 KST로 계속 발송하는 버그가 있어 필수.
    static func updatePushTime(
        _ time: Date,
        user: UserProfile,
        nickname: String,
        modelContext: ModelContext
    ) async throws {
        user.pushTime = time
        try modelContext.save()
        Task { await PushManager.shared.scheduleDailyFortunePush(at: time, nickname: nickname) }
        try await SupabaseAuthManager.updatePushTime(time)
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

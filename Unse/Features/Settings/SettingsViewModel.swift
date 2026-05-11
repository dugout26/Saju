import Foundation
import Observation
import SwiftData
import FirebaseCrashlytics

/// SettingsView의 도메인 액션 (push 토글, 계정 삭제, 로그아웃) + UI 상태.
/// View는 binding + Service 호출 trigger만 담당. 모든 부수 효과는 SettingsService에 위임.
@Observable
@MainActor
final class SettingsViewModel {

    let user: UserProfile?

    // MARK: - UI 상태 (binding)
    var pushEnabled = false
    var pushTime = Date()
    var pushSaveError: String?
    var deleteError: String?
    var logoutError: String?
    var showPaywall = false
    var showDeleteAlert = false
    var showLogoutAlert = false

    /// TimePicker 빠른 스크롤 시 이전 sync task를 취소해 서버 순서 뒤바뀜 방지.
    /// 테스트가 완료를 대기할 수 있게 internal로 노출.
    private(set) var pushSyncTask: Task<Void, Never>?

    init(user: UserProfile?) {
        self.user = user
        loadPushSettings()
    }

    private func loadPushSettings() {
        pushEnabled = user?.pushEnabled ?? false
        pushTime = user?.pushTime ?? Self.defaultPushTime
    }

    // MARK: - 액션

    func setPushEnabled(_ enabled: Bool, modelContext: ModelContext) {
        pushEnabled = enabled
        guard let user else { return }
        pushSyncTask?.cancel()
        pushSyncTask = Task { [weak self] in
            do {
                try await SettingsService.updatePushEnabled(enabled, user: user, modelContext: modelContext)
            } catch is CancellationError {
                return
            } catch {
                Crashlytics.crashlytics().record(error: error)
                self?.pushSaveError = "알림 설정 저장 실패. 다시 시도해주세요."
            }
        }
    }

    func setPushTime(_ time: Date, modelContext: ModelContext) {
        pushTime = time
        guard let user else { return }
        pushSyncTask?.cancel()
        pushSyncTask = Task { [weak self] in
            do {
                try await SettingsService.updatePushTime(
                    time, user: user, nickname: user.nickname, modelContext: modelContext
                )
            } catch is CancellationError {
                return
            } catch {
                Crashlytics.crashlytics().record(error: error)
                self?.pushSaveError = "알림 시간 저장 실패. 다시 시도해주세요."
            }
        }
    }

    func deleteAccount(modelContext: ModelContext) {
        guard let user else { return }
        do {
            try SettingsService.deleteAccount(user: user, modelContext: modelContext)
        } catch {
            Crashlytics.crashlytics().record(error: error)
            deleteError = "계정 삭제 실패. 다시 시도해주세요.\n(\(error.localizedDescription))"
        }
    }

    func logout(modelContext: ModelContext) async {
        guard let user else { return }
        do {
            try await SettingsService.logout(user: user, modelContext: modelContext)
        } catch {
            Crashlytics.crashlytics().record(error: error)
            logoutError = "로그아웃 실패. 잠시 후 다시 시도해주세요.\n(\(error.localizedDescription))"
        }
    }

    // MARK: - Static helpers (UI text 포맷)

    private static var defaultPushTime: Date {
        var comps = DateComponents()
        comps.hour = 8
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }
}

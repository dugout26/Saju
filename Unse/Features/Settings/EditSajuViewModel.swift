import Foundation
import Observation
import SwiftData
import FirebaseCrashlytics

/// EditSajuView의 도메인 로직 + UI 상태 — 권한 검사, save 흐름, alert state.
/// View는 binding + 표시만, 비즈니스 규칙은 모두 SajuEditService에 위임.
@Observable
@MainActor
final class EditSajuViewModel {

    let user: UserProfile

    /// 출생 정보 input/검증/compute. EditSajuView가 input.year 등에 binding하므로 var.
    /// 외부에서 birthVM 자체를 교체할 일은 없지만, SwiftUI Bindable이 keypath 추론에
    /// 필요해서 var.
    var birthVM = BirthInfoViewModel()

    // MARK: - UI 상태 (binding)
    var isSaving = false
    var errorMessage: String?
    var showRecomputeConfirm = false
    var showLimitAlert = false
    var limitMessage = ""
    var showRecomputing = false

    init(user: UserProfile) {
        self.user = user
        prefill()
    }

    // MARK: - Prefill

    private func prefill() {
        birthVM.input.nickname = user.nickname
        guard let saju = user.sajuProfile else { return }
        birthVM.input.calendar = BirthCalendar(rawValue: saju.birthCalendar) ?? .solar
        birthVM.input.year = saju.birthYear
        birthVM.input.month = saju.birthMonth
        birthVM.input.day = saju.birthDay
        birthVM.input.hour = saju.birthHour
        birthVM.input.minute = saju.birthMinute
        birthVM.input.gender = Gender(rawValue: saju.gender) ?? .female
    }

    // MARK: - 출생 필드 변경 감지

    /// 출생 필드(생년월일·시·달력·성별)가 prefill 값과 다른지.
    var birthFieldsChanged: Bool {
        guard let saju = user.sajuProfile else { return true }
        return birthVM.input.calendar.rawValue != saju.birthCalendar
            || birthVM.input.year != saju.birthYear
            || birthVM.input.month != saju.birthMonth
            || birthVM.input.day != saju.birthDay
            || birthVM.input.hour != saju.birthHour
            || birthVM.input.minute != saju.birthMinute
            || birthVM.input.gender.rawValue != saju.gender
    }

    // MARK: - 저장 흐름

    /// 저장 버튼 액션. 닉네임만 변경 시 즉시 닉네임 update,
    /// 출생 정보 변경 시 권한 검사 후 recompute 확인 alert.
    /// - returns: 닉네임만 변경된 경우 true (View가 dismiss 가능). 그 외 false.
    func save(isPremium: Bool, modelContext: ModelContext) async -> Bool {
        errorMessage = nil

        // 닉네임만 변경
        guard birthFieldsChanged else {
            return await performNicknameOnlySave(modelContext: modelContext)
        }

        // 출생 정보 변경 — 권한 검사
        if isPremium {
            if let last = user.sajuProfile?.lastModifiedAt,
               user.sajuModifiedCount > 0,
               !SajuEditService.canEditSajuToday(lastModified: last) {
                limitMessage = "사주 변경은 하루에 한 번만 가능해요. 내일 다시 시도해 주세요."
                showLimitAlert = true
                return false
            }
        } else {
            if let last = user.sajuProfile?.lastModifiedAt,
               user.sajuModifiedCount > 0 {
                let status = SajuEditService.freeMonthlyEditStatus(lastModified: last)
                if !status.allowed {
                    limitMessage = "무료 버전은 30일에 한 번 변경 가능해요.\n약 \(status.daysRemaining)일 후 다시 시도해 주세요.\nPRO는 매일 변경 가능합니다."
                    showLimitAlert = true
                    return false
                }
            }
        }

        // 권한 OK → recompute 확인 alert (사용자 OK 시 confirmRecompute 호출)
        showRecomputeConfirm = true
        return false
    }

    /// recompute 확인 alert에서 "예" 선택 시 호출. 로컬 SwiftData 업데이트 + AnalyzingView 표시.
    /// AnalyzingView가 onSave 콜백으로 SajuEditService.commitRecompute를 부름.
    func confirmRecompute(modelContext: ModelContext) {
        isSaving = true
        do {
            let result = birthVM.compute()
            try SajuEditService.recomputeAndSaveLocally(
                input: birthVM.input, result: result,
                user: user, modelContext: modelContext
            )
            showRecomputing = true
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = "저장 중 오류가 발생했어요. 다시 시도해주세요.\n(\(error.localizedDescription))"
        }
        isSaving = false
    }

    // MARK: - Private

    private func performNicknameOnlySave(modelContext: ModelContext) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            try await SajuEditService.updateNickname(
                birthVM.input.nickname, user: user, modelContext: modelContext
            )
            return true
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = "저장 실패. 다시 시도해주세요.\n(\(error.localizedDescription))"
            return false
        }
    }
}

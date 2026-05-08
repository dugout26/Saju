import Foundation
import SwiftData

// MARK: - SajuEditService
//
// 본인 사주 정보 편집의 부수 효과 (SwiftData mutation + 캐시 무효화 + Supabase sync)를
// View 밖으로 분리. EditSajuView는 UI + 사용자 input만 담당.

@MainActor
enum SajuEditService {

    /// 닉네임만 변경 (사주 재계산 X). 로컬 + 원격 동기화. 성공 시 nil throw.
    /// 로컬 저장 실패는 throw, 원격 동기화 실패는 별도 throw (호출자가 메시지 분기).
    static func updateNickname(
        _ nickname: String,
        user: UserProfile,
        modelContext: ModelContext
    ) async throws {
        user.nickname = nickname
        try modelContext.save()
        try await SupabaseAuthManager.updateNickname(nickname)
    }

    /// 출생정보 변경 (사주 재계산). 로컬 SwiftData만 업데이트 + 캐시 무효화.
    /// Supabase 동기화는 호출자(AnalyzingView)가 분석 모션과 병렬 처리.
    static func recomputeAndSaveLocally(
        input: BirthInput,
        result: (saju: SajuComputed, daeWoon: [DaeWoon]),
        user: UserProfile,
        modelContext: ModelContext
    ) throws {
        user.nickname = input.nickname

        guard let saju = user.sajuProfile else {
            throw SajuEditError.profileMissing
        }

        // 사주 캐시 갱신
        saju.birthCalendar = input.calendar.rawValue
        saju.birthYear = input.year
        saju.birthMonth = input.month
        saju.birthDay = input.day
        saju.birthHour = input.hour
        saju.birthMinute = input.minute
        saju.gender = input.gender.rawValue
        saju.yearStem = result.saju.year.stem.character
        saju.yearBranch = result.saju.year.branch.character
        saju.monthStem = result.saju.month.stem.character
        saju.monthBranch = result.saju.month.branch.character
        saju.dayStem = result.saju.day.stem.character
        saju.dayBranch = result.saju.day.branch.character
        saju.hourStem = result.saju.hour?.stem.character
        saju.hourBranch = result.saju.hour?.branch.character

        // JSON 인코딩 실패 시 빈 문자열 저장하지 말고 throw — 데이터 손상 방지
        let elDict = Dictionary(uniqueKeysWithValues: result.saju.fiveElements.map { ($0.key.rawValue, $0.value) })
        let elData = try JSONEncoder().encode(elDict)
        guard let elJSON = String(data: elData, encoding: .utf8) else {
            throw SajuEditError.encodingFailed
        }
        saju.fiveElementsJSON = elJSON

        let dwData = try JSONEncoder().encode(result.daeWoon)
        guard let dwJSON = String(data: dwData, encoding: .utf8) else {
            throw SajuEditError.encodingFailed
        }
        saju.daeWoonJSON = dwJSON
        saju.lastModifiedAt = Date()

        user.sajuModifiedCount += 1

        // SajuReading 캐시 무효화 — 풀이가 새 사주로 재생성되도록
        invalidateReadings(userId: user.id, modelContext: modelContext)

        try modelContext.save()
    }

    /// 재계산된 사주를 Supabase에 동기화 + 서버 캐시 무효화.
    /// recomputeAndSaveLocally가 로컬 SwiftData 처리 후 AnalyzingView.onSave 경로에서 호출.
    /// session 조회 실패 시 throw — silently skip하면 서버에 옛 풀이가 남아
    /// 다음 stage 호출에서 새 사주와 맞지 않는 캐시 hit 발생.
    static func commitRecompute(
        input: BirthInput,
        saju: SajuComputed,
        daeWoon: [DaeWoon]
    ) async throws {
        let userId = try await SupabaseManager.shared.auth.session.user.id

        // 서버 캐시 무효화 — best-effort. 실패 시 다음 stage 호출에서 stale 반환되지만
        // upsertSajuProfile 동기화는 성공시키는 것이 우선.
        _ = try? await SupabaseManager.shared
            .from("saju_readings")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        _ = try? await SupabaseManager.shared
            .from("daily_fortunes")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        // Supabase 사주 동기화
        try await SupabaseAuthManager.upsertSajuProfile(
            input: input, saju: saju, daeWoon: daeWoon
        )
        try await SupabaseAuthManager.updateNickname(input.nickname)
    }

    /// recompute 시 saju_readings 로컬 캐시 삭제. 서버 캐시는 commitRecompute가 처리.
    /// SwiftData #Predicate는 String.hasPrefix / starts(with:) 변환 미지원 →
    /// 모든 SajuReading fetch 후 Swift-side filter (단일 사용자 + stage 5개 max라 비용 무시).
    private static func invalidateReadings(userId: UUID, modelContext: ModelContext) {
        let prefix = userId.uuidString
        let descriptor = FetchDescriptor<SajuReading>()
        if let all = try? modelContext.fetch(descriptor) {
            for row in all where row.key.hasPrefix(prefix) {
                modelContext.delete(row)
            }
        }
    }
}

enum SajuEditError: LocalizedError {
    case profileMissing
    case encodingFailed
    var errorDescription: String? {
        switch self {
        case .profileMissing:  "사주 정보를 찾을 수 없어요. 다시 시도해주세요."
        case .encodingFailed:  "사주 데이터 변환에 실패했어요. 다시 시도해주세요."
        }
    }
}

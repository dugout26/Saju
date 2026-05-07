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

        let elDict = Dictionary(uniqueKeysWithValues: result.saju.fiveElements.map { ($0.key.rawValue, $0.value) })
        saju.fiveElementsJSON = (try? String(data: JSONEncoder().encode(elDict), encoding: .utf8)) ?? "{}"
        saju.daeWoonJSON = (try? String(data: JSONEncoder().encode(result.daeWoon), encoding: .utf8)) ?? "[]"
        saju.lastModifiedAt = Date()

        user.sajuModifiedCount += 1

        // SajuReading 캐시 무효화 — 풀이가 새 사주로 재생성되도록
        invalidateReadings(userId: user.id, modelContext: modelContext)

        try modelContext.save()
    }

    /// recompute 시 saju_readings 로컬 캐시 삭제. 서버 캐시는 AnalyzingView가
    /// Supabase upsert 시점에 별도 무효화 (또는 서버 함수가 stage 호출 시 새로 생성).
    private static func invalidateReadings(userId: UUID, modelContext: ModelContext) {
        let prefix = userId.uuidString
        let descriptor = FetchDescriptor<SajuReading>(
            predicate: #Predicate { $0.key.starts(with: prefix) }
        )
        if let stale = try? modelContext.fetch(descriptor) {
            for row in stale { modelContext.delete(row) }
        }
    }
}

enum SajuEditError: LocalizedError {
    case profileMissing
    var errorDescription: String? {
        switch self {
        case .profileMissing: "사주 정보를 찾을 수 없어요. 다시 시도해주세요."
        }
    }
}

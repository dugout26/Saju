import Testing
import Foundation
import SwiftData
@testable import Unse

@Suite("OnboardingService.saveLocalProfile — SwiftData 저장")
@MainActor
struct OnboardingServiceTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeFixture(nickname: String = "테스트") -> (BirthInput, SajuComputed, [DaeWoon]) {
        let input = BirthInput(year: 1990, month: 3, day: 15, hour: 12, minute: 0, gender: .male, nickname: nickname)
        let result = Manse.calculate(year: input.year, month: input.month, day: input.day, hour: input.hour, gender: input.gender)
        return (input, result.saju, result.daeWoon)
    }

    @Test("saveLocalProfile(apple) — UserProfile 생성 + authProvider=apple + sajuProfile 연결")
    func saveLocalProfile_apple() throws {
        let context = try makeContext()
        let (input, saju, daeWoon) = makeFixture()

        try OnboardingService.saveLocalProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            authProvider: "apple", modelContext: context
        )

        let users = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(users.count == 1)
        #expect(users.first?.nickname == "테스트")
        #expect(users.first?.authProvider == "apple")
        #expect(users.first?.sajuProfile != nil)
    }

    @Test("saveLocalProfile(kakao) — authProvider=kakao 저장")
    func saveLocalProfile_kakao() throws {
        let context = try makeContext()
        let (input, saju, daeWoon) = makeFixture(nickname: "지수")

        try OnboardingService.saveLocalProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            authProvider: "kakao", modelContext: context
        )

        let users = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(users.first?.authProvider == "kakao")
        #expect(users.first?.nickname == "지수")
    }

    @Test("saveLocalProfile — sajuProfile.displayName과 nickname이 일치")
    func saveLocalProfile_displayNameMatchesNickname() throws {
        let context = try makeContext()
        let (input, saju, daeWoon) = makeFixture(nickname: "민수")

        try OnboardingService.saveLocalProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            authProvider: "apple", modelContext: context
        )

        let users = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(users.first?.sajuProfile?.displayName == "민수")
        #expect(users.first?.sajuProfile?.relation == "본인")
    }

    @Test("saveLocalProfile — sajuProfile에 생년월일 정확 저장")
    func saveLocalProfile_birthFieldsPersisted() throws {
        let context = try makeContext()
        let (input, saju, daeWoon) = makeFixture()

        try OnboardingService.saveLocalProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            authProvider: "apple", modelContext: context
        )

        let users = try context.fetch(FetchDescriptor<UserProfile>())
        let profile = users.first?.sajuProfile
        #expect(profile?.birthYear == 1990)
        #expect(profile?.birthMonth == 3)
        #expect(profile?.birthDay == 15)
        #expect(profile?.birthHour == 12)
        #expect(profile?.gender == Gender.male.rawValue)
    }

    // MARK: - restoreLocalProfile (재로그인 시 서버 → 로컬 복원)

    @Test("restoreLocalProfile — snapshot으로 UserProfile + SajuProfile 재구성")
    func restoreLocalProfile_recreatesFromSnapshot() throws {
        let context = try makeContext()
        var input = BirthInput()
        input.year = 1990; input.month = 3; input.day = 15
        input.hour = 12; input.minute = 0
        input.gender = .male
        input.calendar = .solar
        input.nickname = "복원테스트"

        let snapshot = SupabaseAuthManager.ExistingProfileSnapshot(
            nickname: "복원테스트",
            authProvider: "kakao",
            pushTime: Calendar.current.date(from: DateComponents(hour: 21, minute: 30))!,
            pushEnabled: false,
            input: input
        )

        try OnboardingService.restoreLocalProfile(snapshot: snapshot, modelContext: context)

        let users = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(users.count == 1)
        let u = users.first
        #expect(u?.nickname == "복원테스트")
        #expect(u?.authProvider == "kakao")
        #expect(u?.pushEnabled == false)
        // 사주 프로필도 함께 복원되어 Manse 재계산 결과가 캐시되어야 함.
        #expect(u?.sajuProfile?.birthYear == 1990)
        #expect(u?.sajuProfile?.birthMonth == 3)
        #expect(u?.sajuProfile?.birthDay == 15)
        #expect(u?.sajuProfile?.gender == Gender.male.rawValue)
        // Manse 재계산 → pillar 캐시가 세팅됐는지 확인 (값은 deterministic).
        #expect(u?.sajuProfile?.yearStem.isEmpty == false)
        #expect(u?.sajuProfile?.dayStem.isEmpty == false)
    }

    @Test("restoreLocalProfile — 동일 BirthInput이면 saveLocalProfile과 동일한 pillar 캐시")
    func restoreLocalProfile_deterministicVsSaveLocal() throws {
        let context1 = try makeContext()
        let context2 = try makeContext()
        let (input, saju, daeWoon) = makeFixture(nickname: "검증")

        try OnboardingService.saveLocalProfile(
            input: input, saju: saju, daeWoon: daeWoon,
            authProvider: "apple", modelContext: context1
        )

        let snapshot = SupabaseAuthManager.ExistingProfileSnapshot(
            nickname: input.nickname, authProvider: "apple",
            pushTime: Date(), pushEnabled: true, input: input
        )
        try OnboardingService.restoreLocalProfile(snapshot: snapshot, modelContext: context2)

        let saved = try context1.fetch(FetchDescriptor<UserProfile>()).first?.sajuProfile
        let restored = try context2.fetch(FetchDescriptor<UserProfile>()).first?.sajuProfile

        // Manse가 deterministic이라 동일 BirthInput → 동일 pillar 결과.
        #expect(saved?.yearStem == restored?.yearStem)
        #expect(saved?.monthBranch == restored?.monthBranch)
        #expect(saved?.dayStem == restored?.dayStem)
    }
}

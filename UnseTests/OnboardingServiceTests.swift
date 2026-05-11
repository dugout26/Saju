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
}

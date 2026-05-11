import Testing
import Foundation
import SwiftData
@testable import Unse

@Suite("EditSajuViewModel — 권한 검사 + birthFieldsChanged")
@MainActor
struct EditSajuViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    /// user + sajuProfile 셋업. 출생 1990-03-15 12:00 male, 닉네임 "테스트".
    private func makeUser(_ context: ModelContext, modifiedCount: Int = 0, modifiedAt: Date? = nil) -> UserProfile {
        let input = BirthInput(year: 1990, month: 3, day: 15, hour: 12, minute: 0, gender: .male, nickname: "테스트")
        let result = Manse.calculate(year: input.year, month: input.month, day: input.day, hour: input.hour, gender: input.gender)
        let user = UserProfile(nickname: input.nickname, authProvider: "apple")
        let profile = SajuProfile(input: input, saju: result.saju, daeWoon: result.daeWoon)
        if let modifiedAt { profile.lastModifiedAt = modifiedAt }
        user.sajuProfile = profile
        user.sajuModifiedCount = modifiedCount
        context.insert(user)
        return user
    }

    @Test("prefill — user 정보로 birthVM 초기화")
    func prefill_loadsBirthFields() throws {
        let context = try makeContext()
        let user = makeUser(context)
        let vm = EditSajuViewModel(user: user)
        #expect(vm.birthVM.input.year == 1990)
        #expect(vm.birthVM.input.month == 3)
        #expect(vm.birthVM.input.day == 15)
        #expect(vm.birthVM.input.gender == .male)
        #expect(vm.birthVM.input.nickname == "테스트")
    }

    @Test("birthFieldsChanged — prefill 후엔 false, year 변경 시 true")
    func birthFieldsChanged_detects() throws {
        let context = try makeContext()
        let user = makeUser(context)
        let vm = EditSajuViewModel(user: user)
        #expect(!vm.birthFieldsChanged)

        vm.birthVM.input.year = 1991
        #expect(vm.birthFieldsChanged)
    }

    @Test("save PRO + 어제 변경 → 권한 OK → showRecomputeConfirm")
    func save_pro_yesterday_allowed() async throws {
        let context = try makeContext()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let user = makeUser(context, modifiedCount: 1, modifiedAt: yesterday)
        let vm = EditSajuViewModel(user: user)
        vm.birthVM.input.year = 1991   // 출생 정보 변경

        let dismissable = await vm.save(isPremium: true, modelContext: context)

        #expect(!dismissable)
        #expect(vm.showRecomputeConfirm)
        #expect(!vm.showLimitAlert)
    }

    @Test("save PRO + 오늘 이미 변경 → 차단 alert")
    func save_pro_today_blocked() async throws {
        let context = try makeContext()
        let user = makeUser(context, modifiedCount: 1, modifiedAt: Date())
        let vm = EditSajuViewModel(user: user)
        vm.birthVM.input.year = 1991

        let dismissable = await vm.save(isPremium: true, modelContext: context)

        #expect(!dismissable)
        #expect(vm.showLimitAlert)
        #expect(!vm.showRecomputeConfirm)
        #expect(vm.limitMessage.contains("내일"))
    }

    @Test("save Free + 5일 전 변경 → 차단 alert (약 25일 남음)")
    func save_free_recent_blocked() async throws {
        let context = try makeContext()
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let user = makeUser(context, modifiedCount: 1, modifiedAt: fiveDaysAgo)
        let vm = EditSajuViewModel(user: user)
        vm.birthVM.input.year = 1991

        let dismissable = await vm.save(isPremium: false, modelContext: context)

        #expect(!dismissable)
        #expect(vm.showLimitAlert)
        #expect(vm.limitMessage.contains("30일에 한 번"))
    }

    @Test("save Free + 31일 전 변경 → 권한 OK → showRecomputeConfirm")
    func save_free_old_allowed() async throws {
        let context = try makeContext()
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let user = makeUser(context, modifiedCount: 1, modifiedAt: oldDate)
        let vm = EditSajuViewModel(user: user)
        vm.birthVM.input.year = 1991

        let dismissable = await vm.save(isPremium: false, modelContext: context)

        #expect(!dismissable)
        #expect(vm.showRecomputeConfirm)
        #expect(!vm.showLimitAlert)
    }

    @Test("save Free + 첫 변경 (count=0) → 권한 OK → showRecomputeConfirm")
    func save_free_firstChange_allowed() async throws {
        let context = try makeContext()
        let user = makeUser(context, modifiedCount: 0)
        let vm = EditSajuViewModel(user: user)
        vm.birthVM.input.year = 1991

        let dismissable = await vm.save(isPremium: false, modelContext: context)

        #expect(vm.showRecomputeConfirm)
        #expect(!vm.showLimitAlert)
        #expect(!dismissable)
    }
}

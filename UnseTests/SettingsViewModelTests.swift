import Testing
import Foundation
import SwiftData
@testable import Unse

@Suite("SettingsViewModel — UI 상태 + Service 위임")
@MainActor
struct SettingsViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeUser(_ context: ModelContext, pushEnabled: Bool = true, pushTime: Date? = nil) -> UserProfile {
        let user = UserProfile(
            nickname: "테스트",
            authProvider: "apple",
            pushTime: pushTime ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 30))!,
            pushEnabled: pushEnabled
        )
        context.insert(user)
        return user
    }

    @Test("user nil — pushEnabled false, default pushTime 8:00")
    func init_nilUser_defaults() {
        let vm = SettingsViewModel(user: nil)
        #expect(!vm.pushEnabled)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: vm.pushTime)
        #expect(comps.hour == 8)
        #expect(comps.minute == 0)
    }

    @Test("user 있음 — pushEnabled/pushTime을 user에서 로드")
    func init_withUser_loadsPushSettings() throws {
        let context = try makeContext()
        let custom = Calendar.current.date(from: DateComponents(hour: 21, minute: 15))!
        let user = makeUser(context, pushEnabled: true, pushTime: custom)
        let vm = SettingsViewModel(user: user)
        #expect(vm.pushEnabled)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: vm.pushTime)
        #expect(comps.hour == 21)
        #expect(comps.minute == 15)
    }

    @Test("setPushEnabled — vm.pushEnabled + user.pushEnabled 양쪽 갱신")
    func setPushEnabled_updatesBoth() async throws {
        let context = try makeContext()
        let user = makeUser(context, pushEnabled: false)
        let vm = SettingsViewModel(user: user)
        #expect(!vm.pushEnabled)

        // Supabase 호출은 test env에서 fail해 pushSaveError가 set될 수 있음 — 로컬 갱신만 검증.
        await vm.setPushEnabled(true, modelContext: context)

        #expect(vm.pushEnabled)
        #expect(user.pushEnabled)
    }

    @Test("setPushTime — vm.pushTime + user.pushTime 양쪽 갱신")
    func setPushTime_updatesBoth() async throws {
        let context = try makeContext()
        let user = makeUser(context)
        let vm = SettingsViewModel(user: user)
        let newTime = Calendar.current.date(from: DateComponents(hour: 10, minute: 30))!

        await vm.setPushTime(newTime, modelContext: context)

        #expect(vm.pushTime == newTime)
        #expect(user.pushTime == newTime)
    }

    @Test("deleteAccount — user 삭제 + deleteError nil")
    func deleteAccount_removesUser() throws {
        let context = try makeContext()
        let user = makeUser(context)
        try context.save()
        let vm = SettingsViewModel(user: user)

        vm.deleteAccount(modelContext: context)

        let remaining = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(remaining.isEmpty)
        #expect(vm.deleteError == nil)
    }
}

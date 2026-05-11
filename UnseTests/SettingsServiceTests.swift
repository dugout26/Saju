import Testing
import Foundation
import SwiftData
@testable import Unse

@Suite("SettingsService — SwiftData mutation 검증")
@MainActor
struct SettingsServiceTests {

    /// in-memory SchemaV1 ModelContext — Supabase / PushManager 외부 의존 없이 SwiftData만.
    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeUser(_ context: ModelContext) -> UserProfile {
        let user = UserProfile(nickname: "테스트", authProvider: "apple")
        context.insert(user)
        return user
    }

    @Test("updatePushEnabled(true) — user.pushEnabled = true 저장")
    func updatePushEnabled_setsTrue() async throws {
        let context = try makeContext()
        let user = makeUser(context)
        user.pushEnabled = false

        // Supabase 동기화는 test env에서 fail 가능 — 로컬 저장 검증이 목적이므로 try?.
        _ = try? await SettingsService.updatePushEnabled(true, user: user, modelContext: context)

        #expect(user.pushEnabled)
    }

    @Test("updatePushEnabled(false) — user.pushEnabled = false 저장")
    func updatePushEnabled_setsFalse() async throws {
        let context = try makeContext()
        let user = makeUser(context)
        user.pushEnabled = true

        _ = try? await SettingsService.updatePushEnabled(false, user: user, modelContext: context)

        #expect(!user.pushEnabled)
    }

    @Test("updatePushTime — user.pushTime 갱신")
    func updatePushTime_updates() async throws {
        let context = try makeContext()
        let user = makeUser(context)
        let newTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!

        _ = try? await SettingsService.updatePushTime(newTime, user: user, nickname: "테스트", modelContext: context)

        #expect(user.pushTime == newTime)
    }

    @Test("deleteAccount — modelContext에서 user 제거")
    func deleteAccount_removesUser() throws {
        let context = try makeContext()
        let user = makeUser(context)
        try context.save()
        let id = user.id

        try SettingsService.deleteAccount(user: user, modelContext: context)

        // 동일 id의 user fetch → 0건
        let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == id })
        let remaining = try context.fetch(descriptor)
        #expect(remaining.isEmpty)
    }
}

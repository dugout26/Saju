import SwiftData
import Foundation

@MainActor
final class Repository {
    static let shared = Repository()
    private init() {}

    // MARK: - UserProfile

    func saveUser(_ user: UserProfile, context: ModelContext) throws {
        context.insert(user)
        try context.save()
    }

    func fetchUser(context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        return try? context.fetch(descriptor).first
    }

    // MARK: - DailyFortune

    func fetchTodayFortune(userId: UUID, context: ModelContext) -> DailyFortune? {
        let key = todayKey(userId: userId)
        let descriptor = FetchDescriptor<DailyFortune>(
            predicate: #Predicate { $0.key == key }
        )
        return try? context.fetch(descriptor).first
    }

    func saveFortune(_ fortune: DailyFortune, context: ModelContext) throws {
        context.insert(fortune)
        try context.save()
    }

    func todayKey(userId: UUID) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "\(fmt.string(from: Date()))-\(userId.uuidString)"
    }

    // MARK: - ChatMessages

    func fetchMessages(context: ModelContext) -> [ChatMessage] {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func clearMessages(context: ModelContext) throws {
        try context.fetch(FetchDescriptor<ChatMessage>()).forEach { context.delete($0) }
        try context.save()
    }
}

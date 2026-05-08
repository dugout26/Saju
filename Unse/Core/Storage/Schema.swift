import Foundation
import SwiftData

// SwiftData migration foundation.
// 초반에 VersionedSchema로 묶지 않으면 Phase B에서 schema 변경 시
// migration plan을 retro-fit하기 어려움 (대부분의 SwiftData 예제도 이걸 누락).
// 새 @Model 추가 시 SchemaV1.models에 반드시 등록.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            SajuProfile.self,
            DailyFortune.self,
            ChatMessage.self,
            SajuReading.self
        ]
    }
}

// 향후 schema 변경 시 stages에 MigrationStage 추가.
// 현재는 V1 단일 — empty stages.
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

@MainActor
enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("ModelContainer 초기화 실패: \(error)")
        }
    }()
}

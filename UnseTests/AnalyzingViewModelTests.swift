import Testing
import Foundation
import SwiftData
@testable import Unse

@Suite("AnalyzingViewModel — orchestration (onSave/step/onComplete)")
@MainActor
struct AnalyzingViewModelTests {

    /// in-memory SwiftData container — completeSignup이 호출되지 않더라도
    /// runAnimation 시그니처가 modelContext를 요구.
    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    /// 기본 BirthInput으로 form valid 상태 보장.
    private func makeBirthVM() -> BirthInfoViewModel {
        let vm = BirthInfoViewModel()
        vm.input.nickname = "테스트"
        return vm
    }

    @Test("onSave 콜백이 호출되고 computedResult가 채워짐")
    func runAnimation_onSave_invoked() async throws {
        let mock = MockAPIClient()
        let vm = AnalyzingViewModel(client: mock)
        let birthVM = makeBirthVM()
        let context = try makeContext()

        var onSaveCalled = false
        var savedSaju: SajuComputed?
        await vm.runAnimation(
            birthVM: birthVM,
            stepCount: 2,
            stepDelay: .milliseconds(1),
            finalDelay: .milliseconds(1),
            onSave: { saju, _ in
                onSaveCalled = true
                savedSaju = saju
            },
            onComplete: nil,
            modelContext: context
        )

        #expect(onSaveCalled)
        #expect(savedSaju != nil)
        #expect(vm.computedResult != nil)
        #expect(vm.errorMessage == nil)
    }

    @Test("stepCount 만큼 step이 진행")
    func runAnimation_step_progresses() async throws {
        let vm = AnalyzingViewModel(client: MockAPIClient())
        let birthVM = makeBirthVM()
        let context = try makeContext()

        await vm.runAnimation(
            birthVM: birthVM,
            stepCount: 4,
            stepDelay: .milliseconds(1),
            finalDelay: .milliseconds(1),
            onSave: { _, _ in },
            onComplete: nil,
            modelContext: context
        )

        #expect(vm.step == 4)
    }

    @Test("onComplete 콜백이 정상 흐름에서 호출")
    func runAnimation_onComplete_invoked() async throws {
        let vm = AnalyzingViewModel(client: MockAPIClient())
        let birthVM = makeBirthVM()
        let context = try makeContext()

        var completed = false
        await vm.runAnimation(
            birthVM: birthVM,
            stepCount: 1,
            stepDelay: .milliseconds(1),
            finalDelay: .milliseconds(1),
            onSave: { _, _ in },
            onComplete: { completed = true },
            modelContext: context
        )

        #expect(completed)
    }

    @Test("onSave throws → errorMessage 설정, onComplete 미호출")
    func runAnimation_onSaveThrows_setsErrorMessage() async throws {
        let vm = AnalyzingViewModel(client: MockAPIClient())
        let birthVM = makeBirthVM()
        let context = try makeContext()

        var completed = false
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "저장 실패" }
        }
        await vm.runAnimation(
            birthVM: birthVM,
            stepCount: 1,
            stepDelay: .milliseconds(1),
            finalDelay: .milliseconds(1),
            onSave: { _, _ in throw TestError() },
            onComplete: { completed = true },
            modelContext: context
        )

        #expect(vm.errorMessage == "저장 실패")
        #expect(!completed)
    }
}

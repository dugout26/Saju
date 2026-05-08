import Foundation
import Observation
import SwiftData
import FirebaseCrashlytics

// 사주 분석 진행 상태 + 저장 orchestration — AnalyzingView UI 밖으로 분리.
// SwiftUI 의존성 없음 (testable). withAnimation 제거 — View의
// `.animation(_:value:)` modifier가 step 변화에 반응해 동일 애니메이션 제공.

@Observable
@MainActor
final class AnalyzingViewModel {
    var step = 0
    var errorMessage: String?
    var computedResult: (saju: SajuComputed, daeWoon: [DaeWoon])?

    /// 사주 계산 + 저장 + 풀이 prefetch + 완료 콜백 orchestration.
    /// - stepCount: View가 보여줄 step 수 (animation tick 횟수)
    /// - stepDelay/finalDelay: View가 step별/최종 일시 정지 시간
    /// - onSave: 외부 저장 (edit 흐름). nil이면 OnboardingService.completeSignup
    /// - onComplete: 분석 완료 콜백 (edit 흐름에서 dismiss용; onboarding은 nil — RootView @Query swap)
    func runAnimation(
        birthVM: BirthInfoViewModel,
        stepCount: Int,
        stepDelay: Duration = .seconds(1.1),
        finalDelay: Duration = .seconds(0.5),
        onSave: ((SajuComputed, [DaeWoon]) async throws -> Void)?,
        onComplete: (() -> Void)?,
        modelContext: ModelContext
    ) async {
        let result = birthVM.compute()
        computedResult = result

        // 저장은 animation과 병렬. 부수 효과는 Service에 위임.
        // unstructured Task — 부모 cancel 자동 전파 안 됨. 의도된 동작:
        // view dismiss 후에도 저장은 완료 → 데이터 손실 방지.
        let saveTask = Task {
            try await runSave(birthVM: birthVM, result: result, onSave: onSave, modelContext: modelContext)
        }

        // task cancel(view dismiss) 시 sleep이 throw — try?로 묵살하면 step이 즉시 폭주.
        // do/catch return으로 cleanup. saveTask는 위 주석대로 계속 실행됨.
        for i in 0..<stepCount {
            do {
                try await Task.sleep(for: stepDelay)
            } catch {
                return
            }
            step = i + 1
        }

        do {
            try await saveTask.value
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = error.localizedDescription
            return
        }

        // 풀이 prefetch (background, 결과 무시 — caching 만 됨)
        OnboardingService.prefetchReadings(saju: result.saju, nickname: birthVM.input.nickname)

        // 마지막 pause — cancel 시 onComplete 호출 안 함 (view 이미 dismiss됨)
        do {
            try await Task.sleep(for: finalDelay)
        } catch {
            return
        }

        onComplete?()
    }

    private func runSave(
        birthVM: BirthInfoViewModel,
        result: (saju: SajuComputed, daeWoon: [DaeWoon]),
        onSave: ((SajuComputed, [DaeWoon]) async throws -> Void)?,
        modelContext: ModelContext
    ) async throws {
        if let onSave {
            try await onSave(result.saju, result.daeWoon)
            return
        }
        try await OnboardingService.completeSignup(
            input: birthVM.input,
            saju: result.saju,
            daeWoon: result.daeWoon,
            modelContext: modelContext
        )
    }
}

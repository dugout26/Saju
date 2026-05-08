import Foundation
import Observation

// BirthInfoView가 binding하는 폼 상태 + 만세력 계산 wrapper.
// SwiftUI 의존성 없음 — testable한 unit (Manse 엔진은 pure value type).

@Observable
@MainActor
final class BirthInfoViewModel {
    var input = BirthInput()
    var isLoading = false
    var errorMessage: String?

    var yearText: String { String(input.year) }
    var monthText: String { String(format: "%02d", input.month) }
    var dayText: String { String(format: "%02d", input.day) }
    var hourText: String { input.hour.map { String(format: "%02d", $0) } ?? "" }
    var minText: String { input.minute.map { String(format: "%02d", $0) } ?? "" }

    var formIsValid: Bool { input.isValid && !input.nickname.isEmpty }

    func compute() -> (saju: SajuComputed, daeWoon: [DaeWoon]) {
        Manse.calculate(
            year: input.year, month: input.month, day: input.day,
            hour: input.hour, minute: input.minute,
            calendar: input.calendar, gender: input.gender
        )
    }
}

import Testing
import Foundation
@testable import Unse

@Suite("SajuProfile round-trip — 저장/복원 검증")
@MainActor
struct SajuProfileRoundTripTests {

    // MARK: - SajuComputed reconstruction

    @Test("SajuProfile(input:saju:daeWoon:) → computed → 원본과 동일 stem/branch")
    func computed_roundTrip() {
        let input = makeInput()
        let original = Manse.calculate(
            year: input.year, month: input.month, day: input.day,
            hour: input.hour, minute: input.minute,
            calendar: input.calendar, gender: input.gender
        )
        let profile = SajuProfile(input: input, saju: original.saju, daeWoon: original.daeWoon)
        let restored = profile.computed
        #expect(restored != nil)
        #expect(restored?.year == original.saju.year)
        #expect(restored?.month == original.saju.month)
        #expect(restored?.day == original.saju.day)
        #expect(restored?.hour == original.saju.hour)
    }

    @Test("hour 미상이면 hour stem/branch nil로 저장 + 복원")
    func computed_roundTrip_noHour() {
        var input = makeInput()
        input.hour = nil
        input.minute = nil
        let original = Manse.calculate(
            year: input.year, month: input.month, day: input.day,
            hour: nil, minute: nil,
            calendar: input.calendar, gender: input.gender
        )
        let profile = SajuProfile(input: input, saju: original.saju, daeWoon: original.daeWoon)
        let restored = profile.computed
        #expect(restored != nil)
        #expect(restored?.hour == nil)
    }

    @Test("daeWoon JSON encode → decode 같은 array")
    func daeWoon_roundTrip() {
        let input = makeInput()
        let original = Manse.calculate(
            year: input.year, month: input.month, day: input.day,
            hour: input.hour, minute: input.minute,
            calendar: input.calendar, gender: input.gender
        )
        let profile = SajuProfile(input: input, saju: original.saju, daeWoon: original.daeWoon)
        let restored = profile.daeWoon
        #expect(restored.count == original.daeWoon.count)
        if let first = restored.first, let originalFirst = original.daeWoon.first {
            #expect(first.startAge == originalFirst.startAge)
            #expect(first.pillar == originalFirst.pillar)
            #expect(first.startYear == originalFirst.startYear)
        }
    }

    // MARK: - Helpers

    private func makeInput() -> BirthInput {
        BirthInput(
            calendar: .solar,
            year: 1990, month: 3, day: 15,
            hour: 12, minute: 0,
            gender: .female,
            nickname: "테스트"
        )
    }
}

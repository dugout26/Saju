import Testing
import Foundation
@testable import Unse

@Suite("BirthInfoViewModel — input/format/compute")
@MainActor
struct BirthInfoViewModelTests {

    // MARK: - 기본 input

    @Test("기본 input은 1996-03-15 14:00 여성")
    func defaultInput() {
        let vm = BirthInfoViewModel()
        #expect(vm.input.year == 1996)
        #expect(vm.input.month == 3)
        #expect(vm.input.day == 15)
        #expect(vm.input.hour == 14)
        #expect(vm.input.minute == 0)
        #expect(vm.input.gender == .female)
    }

    // MARK: - formIsValid

    @Test("nickname 빈 값이면 formIsValid false")
    func formIsValid_emptyNickname() {
        let vm = BirthInfoViewModel()
        vm.input.nickname = ""
        #expect(!vm.formIsValid)
    }

    @Test("nickname 채우면 formIsValid true")
    func formIsValid_withNickname() {
        let vm = BirthInfoViewModel()
        vm.input.nickname = "테스트"
        #expect(vm.formIsValid)
    }

    @Test("year 범위 밖 (1899)이면 formIsValid false")
    func formIsValid_yearOutOfRange() {
        let vm = BirthInfoViewModel()
        vm.input.nickname = "테스트"
        vm.input.year = 1899
        #expect(!vm.formIsValid)
    }

    // MARK: - 텍스트 포맷

    @Test("monthText 1자리 month는 zero-padded — 3월 → '03'")
    func monthText_zeroPadded() {
        let vm = BirthInfoViewModel()
        vm.input.month = 3
        #expect(vm.monthText == "03")
    }

    @Test("dayText 2자리 day는 그대로 — 15일 → '15'")
    func dayText_twoDigit() {
        let vm = BirthInfoViewModel()
        vm.input.day = 15
        #expect(vm.dayText == "15")
    }

    @Test("hourText hour=nil이면 빈 문자열")
    func hourText_nilEmpty() {
        let vm = BirthInfoViewModel()
        vm.input.hour = nil
        #expect(vm.hourText == "")
    }

    @Test("hourText hour=14 → '14'")
    func hourText_value() {
        let vm = BirthInfoViewModel()
        vm.input.hour = 14
        #expect(vm.hourText == "14")
    }

    // MARK: - compute()

    @Test("compute() throw 없이 SajuComputed + DaeWoon 반환")
    func compute_returnsResult() {
        let vm = BirthInfoViewModel()
        vm.input.year = 1990
        vm.input.month = 3
        vm.input.day = 15
        vm.input.hour = 12
        let result = vm.compute()
        // 1990-03-15 12:00 — 만세력 결과는 ManseTests에서 검증, 여기선 구조만.
        #expect(result.saju.year.characters.count == 2)
        #expect(result.daeWoon.count > 0)
    }
}

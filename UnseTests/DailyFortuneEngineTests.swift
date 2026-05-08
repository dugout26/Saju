import Testing
import Foundation
@testable import Unse

@Suite("DailyFortuneEngine — pure 도메인")
struct DailyFortuneEngineTests {

    // MARK: - dayPillarString

    @Test("dayPillarString 결정성 — 같은 날짜 두 번 호출 같은 결과")
    func dayPillarString_deterministic() {
        let date = makeDate(2026, 5, 8)
        let first = DailyFortuneEngine.dayPillarString(for: date)
        let second = DailyFortuneEngine.dayPillarString(for: date)
        #expect(first == second)
    }

    @Test("dayPillarString 형식 — 천간(1글자) + 지지(1글자) = 2글자")
    func dayPillarString_format() {
        let date = makeDate(2026, 5, 8)
        let pillar = DailyFortuneEngine.dayPillarString(for: date)
        #expect(pillar.count == 2)
    }

    @Test("dayPillarString 예시 — 2000-01-01 = 戊午 (Manse 부록 B)")
    func dayPillarString_2000_01_01() {
        let date = makeDate(2000, 1, 1)
        let pillar = DailyFortuneEngine.dayPillarString(for: date)
        #expect(pillar == "戊午")
    }

    @Test("dayPillarString 다른 날짜는 다른 일진")
    func dayPillarString_differentDates() {
        let day1 = DailyFortuneEngine.dayPillarString(for: makeDate(2026, 5, 8))
        let day2 = DailyFortuneEngine.dayPillarString(for: makeDate(2026, 5, 9))
        #expect(day1 != day2)
    }

    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return Calendar.current.date(from: comps)!
    }
}

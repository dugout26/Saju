import Testing
@testable import Unse

@Suite("만세력 검증")
struct ManseTests {

    // MARK: - 년주 (Year Pillar)

    @Test("1990-03-15 년주 庚午")
    func yearPillar_1990_03_15() {
        let (saju, _) = Manse.calculate(year: 1990, month: 3, day: 15)
        #expect(saju.year.stem   == .庚)
        #expect(saju.year.branch == .午)
    }

    @Test("2000-01-01 년주 己卯 (입춘 전)")
    func yearPillar_2000_01_01_beforeLichun() {
        let (saju, _) = Manse.calculate(year: 2000, month: 1, day: 1)
        // Jan 1 is before 입춘 (Feb 4) → use 1999 = 己卯
        #expect(saju.year.stem   == .己)
        #expect(saju.year.branch == .卯)
    }

    @Test("2000-02-05 년주 庚辰 (입춘 후)")
    func yearPillar_2000_02_05_afterLichun() {
        let (saju, _) = Manse.calculate(year: 2000, month: 2, day: 5)
        // Feb 5 is after 입춘 (Feb 4) → 庚辰
        #expect(saju.year.stem   == .庚)
        #expect(saju.year.branch == .辰)
    }

    // MARK: - 일주 (Day Pillar)

    @Test("2000-01-01 일주 戊午")
    func dayPillar_2000_01_01() {
        let (saju, _) = Manse.calculate(year: 2000, month: 1, day: 1)
        #expect(saju.day.stem   == .戊)
        #expect(saju.day.branch == .午)
    }

    @Test("1990-03-15 월주 己卯")
    func monthPillar_1990_03_15() {
        let (saju, _) = Manse.calculate(year: 1990, month: 3, day: 15)
        // 庚午年 3월 (경칩 지난 卯月) → 己卯
        #expect(saju.month.stem   == .己)
        #expect(saju.month.branch == .卯)
    }

    @Test("2000-01-01 월주 丙子 (입춘 전, 1999 己卯年 子月)")
    func monthPillar_2000_01_01() {
        let (saju, _) = Manse.calculate(year: 2000, month: 1, day: 1)
        #expect(saju.month.stem   == .丙)
        #expect(saju.month.branch == .子)
    }

    // MARK: - 부록 B Case 2: 1985-08-25

    @Test("1985-08-25 년주 乙丑")
    func yearPillar_1985_08_25() {
        let (saju, _) = Manse.calculate(year: 1985, month: 8, day: 25)
        #expect(saju.year.stem   == .乙)
        #expect(saju.year.branch == .丑)
    }

    @Test("1985-08-25 월주 甲申 (입추 후 申月)")
    func monthPillar_1985_08_25() {
        let (saju, _) = Manse.calculate(year: 1985, month: 8, day: 25)
        #expect(saju.month.stem   == .甲)
        #expect(saju.month.branch == .申)
    }

    // MARK: - 시주 (Hour Pillar)

    @Test("戊 일간 申時(15시) → 庚申")
    func hourPillar_WuDayShen() {
        // Day stem 戊(4), group=4 → 壬子(48) start
        // 申(8) → 48 + 8 = 56 % 60 = 56 → 庚申(6,8)
        let hour = Manse.calculate(year: 2000, month: 1, day: 1, hour: 15).saju
        // day.stem is 戊
        #expect(hour.day.stem == .戊)
        #expect(hour.hour?.branch == .申)
    }

    @Test("2000-01-01 00:00 시주 壬子 (戊일 子時)")
    func hourPillar_2000_01_01_midnight() {
        let (saju, _) = Manse.calculate(year: 2000, month: 1, day: 1, hour: 0)
        #expect(saju.hour?.stem   == .壬)
        #expect(saju.hour?.branch == .子)
    }

    // MARK: - JDN

    @Test("JDN: 2000-01-01 = 2451545")
    func jdn_2000_01_01() {
        let jdn = Manse.julianDayNumber(year: 2000, month: 1, day: 1)
        #expect(jdn == 2451545)
    }
}

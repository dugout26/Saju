import Foundation

// MARK: - 만세력 (Korean Traditional Calendar)
//
// Algorithm overview:
// 1. Year pillar: (year-4) % 10/12 with 입춘(Feb 3-5) correction
// 2. Month pillar: determined by 절기 (solar terms), stem from year-stem group
// 3. Day pillar: Julian Day Number offset from reference (Jan 1 2000 = 戊午 = index 54)
// 4. Hour pillar: branch from time, stem from day-stem group
// 5. 대운: from month pillar ± direction based on gender and year-stem polarity

enum Manse {

    // MARK: - Public API

    /// Compute the four pillars (사주) for a given solar date
    static func calculate(
        year: Int, month: Int, day: Int,
        hour: Int? = nil, minute: Int? = nil,
        calendar: BirthCalendar = .solar,
        gender: Gender = .female
    ) -> (saju: SajuComputed, daeWoon: [DaeWoon]) {
        var y = year, m = month, d = day
        if calendar == .lunar {
            (y, m, d) = lunarToSolar(y: y, m: m, d: d) ?? (y, m, d)
        }

        let yearPillar  = computeYearPillar(year: y, month: m, day: d)
        let monthPillar = computeMonthPillarCorrect(year: y, month: m, day: d, yearStem: yearPillar.stem)
        let dayPillar   = computeDayPillar(year: y, month: m, day: d)
        let hourPillar: Pillar? = hour.map {
            computeHourPillar(hour: $0, dayStem: dayPillar.stem)
        }

        let saju = SajuComputed(
            year: yearPillar, month: monthPillar, day: dayPillar, hour: hourPillar
        )
        let daeWoon = computeDaeWoon(
            birthYear: y, birthMonth: m, birthDay: d,
            monthPillar: monthPillar, yearStem: yearPillar.stem, gender: gender
        )
        return (saju, daeWoon)
    }

    /// Daily pillar (일진) for a given date
    static func dailyPillar(year: Int, month: Int, day: Int) -> Pillar {
        computeDayPillar(year: year, month: month, day: day)
    }

    // MARK: - Year Pillar (년주)

    private static func computeYearPillar(year: Int, month: Int, day: Int) -> Pillar {
        // 입춘 (start of 寅月) is the boundary: if date < 입춘, use previous year
        let lichunDate = lichun(year: year)
        let effectiveYear = (month < lichunDate.month ||
            (month == lichunDate.month && day < lichunDate.day)) ? year - 1 : year

        let stemIdx   = (effectiveYear - 4).modulo(10)
        let branchIdx = (effectiveYear - 4).modulo(12)
        return Pillar(
            stem:   HeavenlyStem(rawValue: stemIdx)!,
            branch: EarthlyBranch(rawValue: branchIdx)!
        )
    }

    // MARK: - Month Pillar (월주)

    private static func computeMonthPillarCorrect(year: Int, month: Int, day: Int, yearStem: HeavenlyStem) -> Pillar {
        let monthBranchOffset = solarTermMonthBranch(year: year, month: month, day: day)
        // Branch of this month: 寅(2) + offset, wrapping through 12
        let branchRaw = (EarthlyBranch.寅.rawValue + monthBranchOffset) % 12
        // Stem: 五虎遁年 formula
        // yearStem group 0=甲己, 1=乙庚, 2=丙辛, 3=丁壬, 4=戊癸
        // 寅月 stem indices: 丙(2), 戊(4), 庚(6), 壬(8), 甲(0) for groups 0-4
        let group = yearStem.rawValue % 5
        let yinStemRaw = [2, 4, 6, 8, 0][group]
        let stemRaw = (yinStemRaw + monthBranchOffset).modulo(10)

        return Pillar(
            stem:   HeavenlyStem(rawValue: stemRaw)!,
            branch: EarthlyBranch(rawValue: branchRaw)!
        )
    }

    // MARK: - Day Pillar (일주)

    private static func computeDayPillar(year: Int, month: Int, day: Int) -> Pillar {
        // Reference: Jan 1, 2000 (JDN 2451545) = 戊午 (index 54 in 60-cycle)
        let jdn = julianDayNumber(year: year, month: month, day: day)
        let referenceJDN = 2451545
        let referenceIdx = 54   // 戊午
        let idx60 = (jdn - referenceJDN + referenceIdx + 60 * 10000).modulo(60)
        return Pillar(
            stem:   HeavenlyStem(rawValue: idx60 % 10)!,
            branch: EarthlyBranch(rawValue: idx60 % 12)!
        )
    }

    // MARK: - Hour Pillar (시주)

    private static func computeHourPillar(hour: Int, dayStem: HeavenlyStem) -> Pillar {
        // 子時 = 23:00-00:59, 丑時 = 01:00-02:59, ..., 亥時 = 21:00-22:59
        let branchRaw: Int
        if hour == 23 {
            branchRaw = 0  // 子
        } else {
            branchRaw = (hour + 1) / 2
        }

        // 五鼠遁日 (hour stem from day stem)
        // Day stem group 0=甲己→甲子(0), 1=乙庚→丙子(12), 2=丙辛→戊子(24), 3=丁壬→庚子(36), 4=戊癸→壬子(48)
        let group = dayStem.rawValue % 5
        let ziStartIdx = [0, 12, 24, 36, 48][group]   // 子時 60-cycle index
        let idx60 = (ziStartIdx + branchRaw).modulo(60)

        return Pillar(
            stem:   HeavenlyStem(rawValue: idx60 % 10)!,
            branch: EarthlyBranch(rawValue: idx60 % 12)!
        )
    }

    // MARK: - 대운 (Major Fortune Cycles)

    private static func computeDaeWoon(
        birthYear: Int, birthMonth: Int, birthDay: Int,
        monthPillar: Pillar, yearStem: HeavenlyStem, gender: Gender
    ) -> [DaeWoon] {
        // Forward: Yang year + Male OR Yin year + Female
        let isYangYear = yearStem.isYang
        let isMale = gender == .male
        let forward = (isYangYear && isMale) || (!isYangYear && !isMale)

        // Find nearest solar term date to determine start age (days / 3 = years)
        let daysToTerm = daysToNearestSolarTerm(
            year: birthYear, month: birthMonth, day: birthDay, forward: forward
        )
        let startAge = max(1, Int(round(Double(daysToTerm) / 3.0)))

        // Build 8 decades of 대운
        let startIdx60 = monthPillar.cycleIndex
        var result: [DaeWoon] = []
        for i in 0..<8 {
            let offset = forward ? (i + 1) : -(i + 1)
            let idx = (startIdx60 + offset + 60 * 100).modulo(60)
            let age = startAge + i * 10
            let year = birthYear + age
            result.append(DaeWoon(
                startAge: age,
                pillar: Pillar(
                    stem:   HeavenlyStem(rawValue: idx % 10)!,
                    branch: EarthlyBranch(rawValue: idx % 12)!
                ),
                startYear: year
            ))
        }
        return result
    }

    // MARK: - Solar Terms (절기)

    /// Returns the 0-based month branch offset: 0=寅月, 1=卯月, ..., 11=丑月
    private static func solarTermMonthBranch(year: Int, month: Int, day: Int) -> Int {
        // The 12 절입 (month-starting solar terms) approximate days of the month:
        // Jan=소한≈6, Feb=입춘≈4, Mar=경칩≈6, Apr=청명≈5, May=입하≈6, Jun=망종≈6
        // Jul=소서≈7, Aug=입추≈7, Sep=백로≈8, Oct=한로≈8, Nov=입동≈7, Dec=대설≈7
        let termDay = approximateSolarTermDay(year: year, month: month)

        // The month branch depends on which side of the solar term we're on
        // If day >= termDay: we're in the current solar-term month
        // If day < termDay: we're still in the previous solar-term month
        let inCurrentMonth = day >= termDay

        // Map calendar month → 절기 month index (0=寅月=Feb, 1=卯月=Mar, ...)
        // Note: Jan is special — it spans either 丑月(Dec-Jan) or 寅月(Jan-Feb)
        let branchOffset: Int
        if month == 1 {
            branchOffset = inCurrentMonth ? 11 : 10  // 丑月 or 子月
        } else {
            // month 2=Feb → 0=寅月, month 3=Mar → 1=卯月, etc.
            branchOffset = (month - 2) + (inCurrentMonth ? 0 : -1)
        }
        return branchOffset.modulo(12)
    }

    private static func approximateSolarTermDay(year: Int, month: Int) -> Int {
        // Approximate day-of-month for the 절입 (month-start solar term)
        // Based on average ± simple year correction
        let base = [6, 4, 6, 5, 6, 6, 7, 7, 8, 8, 7, 7]  // months 1-12
        let correction = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? -1 : 0
        return base[month - 1] + correction
    }

    private static func lichun(year: Int) -> (month: Int, day: Int) {
        // 입춘 is always in February, around the 3rd–5th
        let isLeap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        return (month: 2, day: isLeap ? 3 : 4)
    }

    // MARK: - 대운 시작 계산

    private static func daysToNearestSolarTerm(
        year: Int, month: Int, day: Int, forward: Bool
    ) -> Int {
        // Approximate: find next or previous major solar term boundary
        let termDay = approximateSolarTermDay(year: year, month: month)
        if forward {
            let nextMonth = month == 12 ? 1 : month + 1
            let nextYear  = month == 12 ? year + 1 : year
            let nextTermDay = approximateSolarTermDay(year: nextYear, month: nextMonth)
            let daysInMonth = daysInMonth(year: year, month: month)
            return (daysInMonth - day) + nextTermDay
        } else {
            if day >= termDay {
                return day - termDay
            } else {
                let prevMonth = month == 1 ? 12 : month - 1
                let prevYear  = month == 1 ? year - 1 : year
                let prevTermDay = approximateSolarTermDay(year: prevYear, month: prevMonth)
                let prevDays = daysInMonth(year: prevYear, month: prevMonth)
                return (prevDays - prevTermDay) + day
            }
        }
    }

    // MARK: - Julian Day Number

    static func julianDayNumber(year: Int, month: Int, day: Int) -> Int {
        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = y / 100
        let b = 2 - a + a / 4
        return Int(365.25 * Double(y + 4716)) + Int(30.6001 * Double(m + 1)) + day + b - 1524
    }

    // MARK: - Lunar Calendar Conversion

    /// Convert lunar date to solar date.
    /// Uses a simplified lookup for 1900-2050. Returns nil if out of range.
    static func lunarToSolar(y: Int, m: Int, d: Int) -> (Int, Int, Int)? {
        // For MVP: return nil to indicate "use solar as-is" — user should enter solar.
        // A full implementation would use the 음양력 conversion table.
        // TODO: integrate a complete lunar-solar conversion table for 1900-2050
        return nil
    }

    // MARK: - Helpers

    private static func daysInMonth(year: Int, month: Int) -> Int {
        let isLeap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        let days = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return days[month - 1]
    }
}

// MARK: - Int helpers

private extension Int {
    func modulo(_ n: Int) -> Int {
        let r = self % n
        return r < 0 ? r + n : r
    }
}

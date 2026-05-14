package run.mound.unse.manse

import kotlin.math.roundToInt

/**
 * 만세력 (Korean Traditional Calendar) — Kotlin port of iOS `Manse.swift`.
 *
 * Algorithm:
 * 1. Year pillar: (year-4) % 10/12 with 입춘(Feb 3-5) correction
 * 2. Month pillar: determined by 절기, stem from year-stem group
 * 3. Day pillar: Julian Day Number offset from reference (Jan 1 2000 = 戊午 = index 54)
 * 4. Hour pillar: branch from time, stem from day-stem group
 * 5. 대운: from month pillar ± direction based on gender and year-stem polarity
 *
 * Pure value-type math — no Android dependencies.
 */
object Manse {

    data class Result(val saju: SajuComputed, val daeWoon: List<DaeWoon>)

    /** Compute the four pillars + 대운 for a given (solar) date. */
    fun calculate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = null,
        minute: Int? = null,
        calendar: BirthCalendar = BirthCalendar.SOLAR,
        gender: Gender = Gender.FEMALE
    ): Result {
        var y = year
        var m = month
        var d = day
        if (calendar == BirthCalendar.LUNAR) {
            // CR-4: silent null fallback 금지. lunar 변환 미구현 상태에서 lunar input은 명시적 에러로
            // 호출자가 인지하게 만든다. 양력으로 호출하거나 lunarToSolar 구현 완료 후 재시도.
            val converted = lunarToSolar(y, m, d)
                ?: throw IllegalArgumentException(
                    "Lunar calendar conversion not yet implemented. Use calendar=SOLAR."
                )
            y = converted.first; m = converted.second; d = converted.third
        }

        val yearPillar = computeYearPillar(y, m, d)
        val monthPillar = computeMonthPillarCorrect(y, m, d, yearPillar.stem)
        val dayPillar = computeDayPillar(y, m, d)
        val hourPillar: Pillar? = hour?.let { computeHourPillar(it, dayPillar.stem) }

        val saju = SajuComputed(yearPillar, monthPillar, dayPillar, hourPillar)
        val daeWoon = computeDaeWoon(y, m, d, monthPillar, yearPillar.stem, gender)
        return Result(saju, daeWoon)
    }

    /** Daily pillar (일진) for a given date. */
    fun dailyPillar(year: Int, month: Int, day: Int): Pillar =
        computeDayPillar(year, month, day)

    // MARK: - Year Pillar (년주)

    private fun computeYearPillar(year: Int, month: Int, day: Int): Pillar {
        val lichunDate = lichun(year)
        val effectiveYear = if (
            month < lichunDate.first ||
            (month == lichunDate.first && day < lichunDate.second)
        ) year - 1 else year

        val stemIdx = (effectiveYear - 4).mod(10)
        val branchIdx = (effectiveYear - 4).mod(12)
        return Pillar(Stem.fromIndex(stemIdx), Branch.fromIndex(branchIdx))
    }

    // MARK: - Month Pillar (월주)

    private fun computeMonthPillarCorrect(
        year: Int, month: Int, day: Int, yearStem: Stem
    ): Pillar {
        val offset = solarTermMonthBranch(year, month, day)
        val branchRaw = (Branch.寅.ordinal + offset) % 12
        // 五虎遁年: yearStem group 0=甲己, 1=乙庚, 2=丙辛, 3=丁壬, 4=戊癸
        // 寅月 stem indices: 丙(2), 戊(4), 庚(6), 壬(8), 甲(0) for groups 0-4
        val group = yearStem.ordinal % 5
        val yinStemRaw = intArrayOf(2, 4, 6, 8, 0)[group]
        val stemRaw = (yinStemRaw + offset).mod(10)
        return Pillar(Stem.fromIndex(stemRaw), Branch.fromIndex(branchRaw))
    }

    // MARK: - Day Pillar (일주)

    private fun computeDayPillar(year: Int, month: Int, day: Int): Pillar {
        // Jan 1, 2000 (JDN 2451545) = 戊午 (index 54 in 60-cycle)
        val jdn = julianDayNumber(year, month, day)
        val idx60 = (jdn - 2451545 + 54 + 60 * 10000).mod(60)
        return Pillar(Stem.fromIndex(idx60 % 10), Branch.fromIndex(idx60 % 12))
    }

    // MARK: - Hour Pillar (시주)

    private fun computeHourPillar(hour: Int, dayStem: Stem): Pillar {
        // 子時 = 23:00-00:59, 丑時 = 01:00-02:59, ..., 亥時 = 21:00-22:59
        val branchRaw = if (hour == 23) 0 else (hour + 1) / 2

        // 五鼠遁日: Day stem group 0=甲己→甲子(0), 1=乙庚→丙子(12), 2=丙辛→戊子(24), 3=丁壬→庚子(36), 4=戊癸→壬子(48)
        val group = dayStem.ordinal % 5
        val ziStartIdx = intArrayOf(0, 12, 24, 36, 48)[group]
        val idx60 = (ziStartIdx + branchRaw).mod(60)
        return Pillar(Stem.fromIndex(idx60 % 10), Branch.fromIndex(idx60 % 12))
    }

    // MARK: - 대운 (Major Fortune Cycles)

    private fun computeDaeWoon(
        birthYear: Int, birthMonth: Int, birthDay: Int,
        monthPillar: Pillar, yearStem: Stem, gender: Gender
    ): List<DaeWoon> {
        // Forward: Yang year + Male OR Yin year + Female
        val isYangYear = yearStem.isYang
        val isMale = gender == Gender.MALE
        val forward = (isYangYear && isMale) || (!isYangYear && !isMale)

        val daysToTerm = daysToNearestSolarTerm(birthYear, birthMonth, birthDay, forward)
        val startAge = maxOf(1, (daysToTerm / 3.0).roundToInt())

        val startIdx60 = monthPillar.cycleIndex
        val result = mutableListOf<DaeWoon>()
        for (i in 0 until 8) {
            val offset = if (forward) i + 1 else -(i + 1)
            val idx = (startIdx60 + offset + 60 * 100).mod(60)
            val age = startAge + i * 10
            val year = birthYear + age
            result.add(
                DaeWoon(
                    startAge = age,
                    pillar = Pillar(Stem.fromIndex(idx % 10), Branch.fromIndex(idx % 12)),
                    startYear = year
                )
            )
        }
        return result
    }

    // MARK: - Solar Terms (절기)

    /** 0-based month branch offset: 0=寅月, 1=卯月, ..., 11=丑月 */
    private fun solarTermMonthBranch(year: Int, month: Int, day: Int): Int {
        val termDay = approximateSolarTermDay(year, month)
        val inCurrentMonth = day >= termDay

        val branchOffset = if (month == 1) {
            if (inCurrentMonth) 11 else 10
        } else {
            (month - 2) + if (inCurrentMonth) 0 else -1
        }
        return branchOffset.mod(12)
    }

    private fun approximateSolarTermDay(year: Int, month: Int): Int {
        val base = intArrayOf(6, 4, 6, 5, 6, 6, 7, 7, 8, 8, 7, 7)
        val correction = if (isLeapYear(year)) -1 else 0
        return base[month - 1] + correction
    }

    private fun lichun(year: Int): Pair<Int, Int> {
        // 입춘 in February, around the 3rd-5th
        return 2 to if (isLeapYear(year)) 3 else 4
    }

    private fun daysToNearestSolarTerm(
        year: Int, month: Int, day: Int, forward: Boolean
    ): Int {
        val termDay = approximateSolarTermDay(year, month)
        return if (forward) {
            // CR-5: forward 분기에서 이번 달 절기가 아직 안 지난 경우 (day < termDay) 처리.
            // iOS Manse.swift는 이 케이스를 동일하게 처리하지 않아 보수적으로 추가.
            if (day < termDay) {
                termDay - day
            } else {
                val nextMonth = if (month == 12) 1 else month + 1
                val nextYear = if (month == 12) year + 1 else year
                val nextTermDay = approximateSolarTermDay(nextYear, nextMonth)
                val dim = daysInMonth(year, month)
                (dim - day) + nextTermDay
            }
        } else {
            if (day >= termDay) {
                day - termDay
            } else {
                val prevMonth = if (month == 1) 12 else month - 1
                val prevYear = if (month == 1) year - 1 else year
                val prevTermDay = approximateSolarTermDay(prevYear, prevMonth)
                val prevDays = daysInMonth(prevYear, prevMonth)
                (prevDays - prevTermDay) + day
            }
        }
    }

    // MARK: - Julian Day Number

    fun julianDayNumber(year: Int, month: Int, day: Int): Int {
        var y = year
        var m = month
        if (m <= 2) {
            y -= 1
            m += 12
        }
        val a = y / 100
        val b = 2 - a + a / 4
        return (365.25 * (y + 4716)).toInt() +
               (30.6001 * (m + 1)).toInt() +
               day + b - 1524
    }

    // MARK: - Lunar Calendar (TODO: full lookup table)

    fun lunarToSolar(y: Int, m: Int, d: Int): Triple<Int, Int, Int>? {
        // MVP: return null → caller treats input as solar. Full lookup table TBD.
        return null
    }

    // MARK: - Helpers

    private fun daysInMonth(year: Int, month: Int): Int {
        val days = intArrayOf(31, if (isLeapYear(year)) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
        return days[month - 1]
    }

    private fun isLeapYear(year: Int): Boolean =
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

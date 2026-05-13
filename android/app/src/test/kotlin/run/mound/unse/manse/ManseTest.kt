package run.mound.unse.manse

import org.junit.Test
import kotlin.test.assertEquals

/**
 * 만세력 검증 — iOS `UnseTests/ManseTests.swift`와 동일한 fixture cases.
 * iOS Swift 결과와 1:1로 일치해야 함.
 */
class ManseTest {

    // MARK: - 년주 (Year Pillar)

    @Test
    fun `1990-03-15 년주 庚午`() {
        val (saju, _) = Manse.calculate(year = 1990, month = 3, day = 15)
        assertEquals(Stem.庚, saju.year.stem)
        assertEquals(Branch.午, saju.year.branch)
    }

    @Test
    fun `2000-01-01 년주 己卯 (입춘 전)`() {
        val (saju, _) = Manse.calculate(year = 2000, month = 1, day = 1)
        // Jan 1 < 입춘(Feb 4) → 1999 = 己卯
        assertEquals(Stem.己, saju.year.stem)
        assertEquals(Branch.卯, saju.year.branch)
    }

    @Test
    fun `2000-02-05 년주 庚辰 (입춘 후)`() {
        val (saju, _) = Manse.calculate(year = 2000, month = 2, day = 5)
        // Feb 5 > 입춘(Feb 4) → 庚辰
        assertEquals(Stem.庚, saju.year.stem)
        assertEquals(Branch.辰, saju.year.branch)
    }

    @Test
    fun `1985-08-25 년주 乙丑`() {
        val (saju, _) = Manse.calculate(year = 1985, month = 8, day = 25)
        assertEquals(Stem.乙, saju.year.stem)
        assertEquals(Branch.丑, saju.year.branch)
    }

    // MARK: - 일주 (Day Pillar)

    @Test
    fun `2000-01-01 일주 戊午`() {
        val (saju, _) = Manse.calculate(year = 2000, month = 1, day = 1)
        assertEquals(Stem.戊, saju.day.stem)
        assertEquals(Branch.午, saju.day.branch)
    }

    // MARK: - 월주 (Month Pillar)

    @Test
    fun `1990-03-15 월주 己卯`() {
        val (saju, _) = Manse.calculate(year = 1990, month = 3, day = 15)
        // 庚午年 3월 (경칩 지난 卯月) → 己卯
        assertEquals(Stem.己, saju.month.stem)
        assertEquals(Branch.卯, saju.month.branch)
    }

    @Test
    fun `2000-01-01 월주 丙子 (입춘 전, 1999 己卯年 子月)`() {
        val (saju, _) = Manse.calculate(year = 2000, month = 1, day = 1)
        assertEquals(Stem.丙, saju.month.stem)
        assertEquals(Branch.子, saju.month.branch)
    }

    @Test
    fun `1985-08-25 월주 甲申 (입추 후 申月)`() {
        val (saju, _) = Manse.calculate(year = 1985, month = 8, day = 25)
        assertEquals(Stem.甲, saju.month.stem)
        assertEquals(Branch.申, saju.month.branch)
    }

    // MARK: - 시주 (Hour Pillar)

    @Test
    fun `戊 일간 申時(15시) → 庚申`() {
        // 2000-01-01 일간 戊, 15시 → 申時
        // 戊 group=4 → 壬子(48) start, 申(8) → 48+8=56 → 庚申(6,8)
        val (saju, _) = Manse.calculate(year = 2000, month = 1, day = 1, hour = 15)
        assertEquals(Stem.戊, saju.day.stem)
        assertEquals(Stem.庚, saju.hour!!.stem)
        assertEquals(Branch.申, saju.hour.branch)
    }

    // MARK: - JDN

    @Test
    fun `JDN Jan 1 2000 = 2451545`() {
        assertEquals(2451545, Manse.julianDayNumber(2000, 1, 1))
    }

    // MARK: - 60갑자 cycle

    @Test
    fun `Pillar cycleIndex 戊午 = 54`() {
        assertEquals(54, Pillar(Stem.戊, Branch.午).cycleIndex)
    }

    @Test
    fun `Pillar cycleIndex 甲子 = 0`() {
        assertEquals(0, Pillar(Stem.甲, Branch.子).cycleIndex)
    }

    // MARK: - 오행 균형

    @Test
    fun `오행 균형 합 = pillar 수 x 2`() {
        val (saju, _) = Manse.calculate(year = 1990, month = 3, day = 15, hour = 12)
        // 4 pillars × (stem+branch) = 8 element occurrences
        val total = saju.fiveElements.values.sum()
        assertEquals(8, total)
    }

    // MARK: - 대운 (Major Fortune)

    @Test
    fun `대운 8개 생성`() {
        val (_, dw) = Manse.calculate(
            year = 1990, month = 3, day = 15, hour = 12,
            gender = Gender.MALE
        )
        assertEquals(8, dw.size)
    }

    @Test
    fun `대운 startAge 증가 = 10년 간격`() {
        val (_, dw) = Manse.calculate(
            year = 1990, month = 3, day = 15, hour = 12,
            gender = Gender.MALE
        )
        for (i in 1 until dw.size) {
            assertEquals(10, dw[i].startAge - dw[i - 1].startAge)
        }
    }

    // MARK: - CR-4 lunar 명시 에러

    @Test
    fun `lunar input → IllegalArgumentException (변환 미구현)`() {
        try {
            Manse.calculate(
                year = 1990, month = 3, day = 15,
                calendar = BirthCalendar.LUNAR
            )
            error("Expected IllegalArgumentException not thrown")
        } catch (_: IllegalArgumentException) {
            // OK
        }
    }

    // MARK: - DailyFortuneEngine

    @Test
    fun `DailyFortuneEngine dayPillarString 2000-01-01 = 戊午`() {
        val s = DailyFortuneEngine.dayPillarString(java.time.LocalDate.of(2000, 1, 1))
        assertEquals("戊午", s)
    }

    // MARK: - CR-8 BirthInput.isValid (LocalDate 검증)

    @Test
    fun `BirthInput 유효 — 1990-03-15`() {
        assertEquals(true, BirthInput(year = 1990, month = 3, day = 15).isValid)
    }

    @Test
    fun `BirthInput 무효 — 2월 30일`() {
        assertEquals(false, BirthInput(year = 1990, month = 2, day = 30).isValid)
    }

    @Test
    fun `BirthInput 무효 — 연도 1899`() {
        assertEquals(false, BirthInput(year = 1899, month = 3, day = 15).isValid)
    }

    @Test
    fun `BirthInput 무효 — hour 24`() {
        assertEquals(false, BirthInput(year = 1990, month = 3, day = 15, hour = 24).isValid)
    }
}

package run.mound.unse.manse

import java.time.DateTimeException
import java.time.LocalDate
import java.time.LocalTime
import java.time.Year

// MARK: - 오행 (Five Elements)
enum class Element(val character: String, val korean: String) {
    WOOD("木", "목"),
    FIRE("火", "화"),
    EARTH("土", "토"),
    METAL("金", "금"),
    WATER("水", "수")
}

// MARK: - 천간 (Heavenly Stems) — 甲乙丙丁戊己庚辛壬癸 (0..9)
enum class Stem(val character: String, val korean: String, val element: Element) {
    甲("甲", "갑", Element.WOOD),
    乙("乙", "을", Element.WOOD),
    丙("丙", "병", Element.FIRE),
    丁("丁", "정", Element.FIRE),
    戊("戊", "무", Element.EARTH),
    己("己", "기", Element.EARTH),
    庚("庚", "경", Element.METAL),
    辛("辛", "신", Element.METAL),
    壬("壬", "임", Element.WATER),
    癸("癸", "계", Element.WATER);

    val index: Int get() = ordinal
    val isYang: Boolean get() = ordinal % 2 == 0

    companion object {
        fun fromIndex(i: Int): Stem = entries[i.mod(10)]
    }
}

// MARK: - 지지 (Earthly Branches) — 子丑寅卯辰巳午未申酉戌亥 (0..11)
enum class Branch(val character: String, val korean: String, val element: Element) {
    子("子", "자", Element.WATER),
    丑("丑", "축", Element.EARTH),
    寅("寅", "인", Element.WOOD),
    卯("卯", "묘", Element.WOOD),
    辰("辰", "진", Element.EARTH),
    巳("巳", "사", Element.FIRE),
    午("午", "오", Element.FIRE),
    未("未", "미", Element.EARTH),
    申("申", "신", Element.METAL),
    酉("酉", "유", Element.METAL),
    戌("戌", "술", Element.EARTH),
    亥("亥", "해", Element.WATER);

    val index: Int get() = ordinal

    companion object {
        fun fromIndex(i: Int): Branch = entries[i.mod(12)]
    }
}

// MARK: - 기둥 (Pillar)
data class Pillar(val stem: Stem, val branch: Branch) {
    val characters: String get() = stem.character + branch.character

    /** Index in the 60-cycle (육십갑자) */
    val cycleIndex: Int
        get() {
            for (i in 0 until 60) {
                if (i % 10 == stem.ordinal && i % 12 == branch.ordinal) return i
            }
            return 0
        }
}

// MARK: - 사주 계산 결과
data class SajuComputed(
    val year: Pillar,
    val month: Pillar,
    val day: Pillar,
    val hour: Pillar?
) {
    val dayMaster: Stem get() = day.stem

    val pillars: List<Pillar> get() = listOfNotNull(year, month, day, hour)

    val fiveElements: Map<Element, Int>
        get() {
            val counts = Element.entries.associateWith { 0 }.toMutableMap()
            for (p in pillars) {
                counts[p.stem.element] = (counts[p.stem.element] ?: 0) + 1
                counts[p.branch.element] = (counts[p.branch.element] ?: 0) + 1
            }
            return counts
        }

    val dominantElement: Element
        get() = fiveElements.maxByOrNull { it.value }?.key ?: Element.EARTH
}

// MARK: - 대운 (Major Fortune Cycle)
data class DaeWoon(val startAge: Int, val pillar: Pillar, val startYear: Int)

// MARK: - 생년월일 입력
enum class BirthCalendar(val korean: String) { SOLAR("양력"), LUNAR("음력") }

enum class Gender(val korean: String) { FEMALE("여성"), MALE("남성") }

data class BirthInput(
    val calendar: BirthCalendar = BirthCalendar.SOLAR,
    val year: Int = 1996,
    val month: Int = 3,
    val day: Int = 15,
    val hour: Int? = 14,
    val minute: Int? = 0,
    val gender: Gender = Gender.FEMALE,
    val nickname: String = ""
) {
    /**
     * 출생 정보 유효성 검사.
     * - 연도: 1900~현재 (CR-7: 2025 hardcode 대신 동적 currentYear)
     * - 날짜: LocalDate로 실존 검증 (CR-8: 2월 30일 같은 invalid date 차단)
     * - 시각: hour 0..23, minute 0..59 + LocalTime 검증
     */
    val isValid: Boolean
        get() {
            val currentYear = Year.now().value
            if (year !in 1900..currentYear) return false
            return try {
                LocalDate.of(year, month, day)
                if (hour != null) LocalTime.of(hour, minute ?: 0)
                true
            } catch (_: DateTimeException) {
                false
            }
        }
}

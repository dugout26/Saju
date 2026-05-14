package run.mound.unse.manse

import java.time.LocalDate
import java.time.ZoneId

/**
 * 매일 운세 도우미.
 *
 * iOS `DailyFortuneEngine.swift` 1:1 대응.
 * 색·방향·시간·숫자 매핑은 LLM (Edge Function `daily-fortune`)이 담당 →
 * 여기에는 클라이언트가 직접 해야 하는 만세력 작업 (오늘 일진) 만 남김.
 */
object DailyFortuneEngine {

    /**
     * 주어진 날짜의 일주(day pillar) 문자열. 예: "庚午"
     *
     * @param date 기준 날짜 (기본: 시스템 today)
     * @param zoneId year/month/day 추출 기준 timezone. KST 강제하려면 `ZoneId.of("Asia/Seoul")`.
     */
    fun dayPillarString(
        date: LocalDate = LocalDate.now(),
        zoneId: ZoneId = ZoneId.systemDefault()
    ): String {
        val zonedDate = date.atStartOfDay(zoneId).toLocalDate()
        val pillar = Manse.dailyPillar(zonedDate.year, zonedDate.monthValue, zonedDate.dayOfMonth)
        return pillar.characters
    }
}

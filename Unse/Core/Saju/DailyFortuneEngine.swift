import Foundation

// MARK: - 매일 운세 도우미
//
// 색·방향·시간·숫자 매핑은 LLM(Edge Function `daily-fortune`)이 담당하므로
// 이 파일에는 "오늘 일진 계산" 같은 클라이언트가 직접 해야 하는 만세력 작업과
// 서버 응답을 UI에 매핑하는 DTO만 남김.

enum DailyFortuneEngine {

    /// 주어진 날짜의 일진(day pillar) 문자열. 예: "庚午"
    static func dayPillarString(for date: Date = Date()) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let pillar = Manse.calculate(
            year:  comps.year  ?? 2026,
            month: comps.month ?? 1,
            day:   comps.day   ?? 1
        ).saju.day
        return pillar.characters
    }
}

// MARK: - 서버 응답 → UI snapshot

struct DailyFortuneSnapshot: Sendable, Equatable, Identifiable {
    let id = UUID()
    let oneLiner: String
    let theme: FortuneTheme
    let luckyColorName: String     // "라벤더", "코랄" 등 LLM 생성
    let luckyColorHex: String      // "#XXXXXX" LLM 생성
    let luckyDirectionKorean: String
    let luckyTimeLabel: String     // "申時 · 신시 (15-17시)"
    let luckyTimeStartHour: Int
    let luckyTimeEndHour: Int
    let luckyNumbers: [Int]
    let avoid: String

    init(dto: DailyFortuneDTO) {
        self.oneLiner = dto.one_liner
        self.theme = FortuneTheme(rawValue: dto.lucky_color_theme ?? "") ?? .lavender
        self.luckyColorName = dto.lucky_color_name ?? dto.lucky_color_secondary ?? "오늘의 색"
        self.luckyColorHex = dto.lucky_color_primary
        self.luckyDirectionKorean = dto.lucky_direction
        self.luckyTimeLabel = dto.lucky_time_label ?? ""
        self.luckyTimeStartHour = Self.parseHour(dto.lucky_time_start)
        self.luckyTimeEndHour = Self.parseHour(dto.lucky_time_end)
        self.luckyNumbers = dto.lucky_numbers
        self.avoid = dto.avoid
    }

    private static func parseHour(_ s: String) -> Int {
        Int(s.prefix(2)) ?? 0
    }
}

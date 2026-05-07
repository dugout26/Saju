import Foundation

// MARK: - DTO

struct DailyFortuneSnapshot: Sendable, Equatable {
    let date: Date
    let dayPillar: Pillar
    let luckyElement: Element
    let theme: FortuneTheme
    let luckyDirectionKorean: String
    let luckyDirectionHanja: String      // "東 · 木"
    let luckyTimeStartHour: Int
    let luckyTimeEndHour: Int
    let luckyTimeBranchLabel: String     // "申時 · 신시"
    let luckyNumbers: [Int]
    let avoid: String
    let oneLiner: String                 // Phase B에서 LLM 결과로 교체
}

// MARK: - Engine (pure functions)

enum DailyFortuneEngine {

    static func compute(saju: SajuComputed, date: Date = Date()) -> DailyFortuneSnapshot {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let dayP = Manse.calculate(
            year:  comps.year  ?? 2026,
            month: comps.month ?? 1,
            day:   comps.day   ?? 1
        ).saju.day

        let lucky = luckyElement(for: saju)
        let dir   = directionLabels(for: lucky)
        let time  = timeLabels(for: lucky)

        return DailyFortuneSnapshot(
            date: date,
            dayPillar: dayP,
            luckyElement: lucky,
            theme: theme(for: lucky),
            luckyDirectionKorean: dir.korean,
            luckyDirectionHanja:  dir.hanja,
            luckyTimeStartHour:   time.start,
            luckyTimeEndHour:     time.end,
            luckyTimeBranchLabel: time.label,
            luckyNumbers: numbers(for: lucky),
            avoid: avoid(saju: saju, dayPillar: dayP),
            oneLiner: oneLinerMock(theme: theme(for: lucky))
        )
    }

    // MARK: - 매핑 (internal, testable)

    /// 사주에서 가장 부족한 오행 = 보충해야 할 luckyElement
    static func luckyElement(for saju: SajuComputed) -> Element {
        saju.fiveElements.min(by: { $0.value < $1.value })?.key ?? .earth
    }

    /// 오행 → FortuneTheme (디자인 3 테마: lavender/peach/mint).
    /// earth는 cream 톤 부재로 peach에 흡수.
    static func theme(for element: Element) -> FortuneTheme {
        switch element {
        case .wood:  .mint
        case .fire:  .peach
        case .earth: .peach
        case .metal: .lavender
        case .water: .lavender
        }
    }

    /// 표준 명리학 방위
    static func directionLabels(for element: Element) -> (korean: String, hanja: String) {
        switch element {
        case .wood:  ("동쪽", "東 · 木")
        case .fire:  ("남쪽", "南 · 火")
        case .earth: ("중앙", "中 · 土")
        case .metal: ("서쪽", "西 · 金")
        case .water: ("북쪽", "北 · 水")
        }
    }

    /// 河圖 숫자
    static func numbers(for element: Element) -> [Int] {
        switch element {
        case .water: [1, 6]
        case .fire:  [2, 7]
        case .wood:  [3, 8]
        case .metal: [4, 9]
        case .earth: [5, 10]
        }
    }

    /// 오행 → 12지 중 대표 시간대
    static func timeLabels(for element: Element) -> (start: Int, end: Int, label: String) {
        switch element {
        case .wood:  (5,  7,  "卯時 · 묘시")
        case .fire:  (11, 13, "午時 · 오시")
        case .earth: (13, 15, "未時 · 미시")
        case .metal: (15, 17, "申時 · 신시")
        case .water: (23, 1,  "子時 · 자시")
        }
    }

    /// 일진 지지가 사주 지지를 六沖하면 충 메시지
    static func avoid(saju: SajuComputed, dayPillar: Pillar) -> String {
        let opposite = sixOpposite(of: dayPillar.branch)
        let sajuBranches = saju.pillars.map(\.branch)
        if sajuBranches.contains(opposite) {
            return "충(沖)이 있는 흐름 — 큰 결정은 한 박자 미루기"
        }
        return "급한 판단보다 차분한 호흡으로 해석됩니다"
    }

    /// 六沖 매핑
    static func sixOpposite(of branch: EarthlyBranch) -> EarthlyBranch {
        switch branch {
        case .子: .午; case .午: .子
        case .丑: .未; case .未: .丑
        case .寅: .申; case .申: .寅
        case .卯: .酉; case .酉: .卯
        case .辰: .戌; case .戌: .辰
        case .巳: .亥; case .亥: .巳
        }
    }

    /// Phase B에서 LLM 호출로 교체
    private static func oneLinerMock(theme: FortuneTheme) -> String {
        switch theme {
        case .lavender: "차분히 듣는 자세가\n예상 밖의 인연을 부르는 흐름입니다."
        case .peach:    "따뜻한 마음 한 마디가\n오늘 분위기를 바꾸는 하루입니다."
        case .mint:     "새로운 시도가\n예상보다 자연스럽게 풀리는 흐름입니다."
        }
    }
}

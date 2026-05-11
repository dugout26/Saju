import Testing
import Foundation
@testable import Unse

@Suite("SajuEditService.canEditSajuToday — KST 자정 기준")
struct SajuEditServiceTests {

    private static let kst = TimeZone(identifier: "Asia/Seoul")!

    /// KST의 특정 날짜·시각으로 Date 생성.
    private static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = kst
        return c.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    @Test("어제 변경 → 오늘은 변경 가능")
    func yesterday_canEditToday() {
        let last = Self.date(2026, 5, 10, 23, 0)   // 5/10 23:00 KST
        let now  = Self.date(2026, 5, 11, 9, 0)    // 5/11 09:00 KST (10시간 경과)
        #expect(SajuEditService.canEditSajuToday(lastModified: last, now: now))
    }

    @Test("같은 날 변경 → 오늘은 차단")
    func sameDay_blocked() {
        let last = Self.date(2026, 5, 11, 0, 30)   // 5/11 00:30
        let now  = Self.date(2026, 5, 11, 23, 59)  // 5/11 23:59 (23.5시간 경과)
        #expect(!SajuEditService.canEditSajuToday(lastModified: last, now: now))
    }

    @Test("정확히 KST 자정 경계 — 어제 23:59 → 오늘 00:00 변경 가능")
    func midnightBoundary_canEdit() {
        let last = Self.date(2026, 5, 10, 23, 59)
        let now  = Self.date(2026, 5, 11, 0, 0)    // 1분 경과지만 KST 날짜가 바뀜
        #expect(SajuEditService.canEditSajuToday(lastModified: last, now: now))
    }

    @Test("이틀 전 → 오늘 변경 가능 (당연)")
    func twoDaysAgo_canEdit() {
        let last = Self.date(2026, 5, 9, 12, 0)
        let now  = Self.date(2026, 5, 11, 12, 0)
        #expect(SajuEditService.canEditSajuToday(lastModified: last, now: now))
    }
}

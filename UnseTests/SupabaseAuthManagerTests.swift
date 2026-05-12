import Testing
import Foundation
@testable import Unse

@Suite("SupabaseAuthManager.kstTimeString — Date → KST HH:mm:ss 변환")
struct SupabaseAuthManagerTests {

    /// `Date` 생성 헬퍼 — UTC 기준으로 timestamp 명확히 지정.
    private func date(year: Int = 2026, month: Int = 5, day: Int = 12,
                      hour: Int, minute: Int, second: Int = 0,
                      timeZone: String = "UTC") -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timeZone)!
        return cal.date(from: comps)!
    }

    @Test("UTC 00:00 → KST 09:00")
    func utcMidnight_isKst9() {
        let d = date(hour: 0, minute: 0, timeZone: "UTC")
        #expect(SupabaseAuthManager.kstTimeString(from: d) == "09:00:00")
    }

    @Test("KST 07:30 → 07:30:00")
    func kst0730_roundtrips() {
        let d = date(hour: 7, minute: 30, timeZone: "Asia/Seoul")
        #expect(SupabaseAuthManager.kstTimeString(from: d) == "07:30:00")
    }

    @Test("KST 23:45 → 23:45:00 (자정 직전)")
    func kstNearMidnight() {
        let d = date(hour: 23, minute: 45, timeZone: "Asia/Seoul")
        #expect(SupabaseAuthManager.kstTimeString(from: d) == "23:45:00")
    }

    @Test("UTC 15:00 → KST 00:00 (자정 wrap-around)")
    func utcAfternoon_wrapsToKstMidnight() {
        let d = date(hour: 15, minute: 0, timeZone: "UTC")
        #expect(SupabaseAuthManager.kstTimeString(from: d) == "00:00:00")
    }

    @Test("기본 8:00 사용자 default — Calendar.current 기반 Date도 KST 변환")
    func defaultPushTime_convertsViaKst() {
        // UserProfile.init의 default pushTime = Calendar.current 기준 8:00.
        // CI runner timezone에 따라 KST 변환 결과가 달라지므로 일관 검증을 위해
        // KST 8:00을 직접 만들어 검증.
        let d = date(hour: 8, minute: 0, timeZone: "Asia/Seoul")
        #expect(SupabaseAuthManager.kstTimeString(from: d) == "08:00:00")
    }

    // MARK: - parsePushTimeKST (재로그인 복원 시 PostgreSQL time → Date)

    @Test("parsePushTimeKST — '07:30:00' → KST 07:30 Date")
    func parsePushTime_kst0730() {
        let result = SupabaseAuthManager.parsePushTimeKST("07:30:00")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let comps = cal.dateComponents([.hour, .minute], from: result)
        #expect(comps.hour == 7)
        #expect(comps.minute == 30)
    }

    @Test("parsePushTimeKST — '23:00:00' → KST 23:00 Date")
    func parsePushTime_kstLate() {
        let result = SupabaseAuthManager.parsePushTimeKST("23:00:00")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let comps = cal.dateComponents([.hour, .minute], from: result)
        #expect(comps.hour == 23)
        #expect(comps.minute == 0)
    }

    @Test("parsePushTimeKST — 깨진 문자열 → KST 8:00 fallback")
    func parsePushTime_invalidString_fallback() {
        let result = SupabaseAuthManager.parsePushTimeKST("invalid")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let comps = cal.dateComponents([.hour, .minute], from: result)
        #expect(comps.hour == 8)
        #expect(comps.minute == 0)
    }
}

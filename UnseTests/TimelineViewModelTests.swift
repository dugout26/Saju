import Testing
import Foundation
@testable import Unse

@Suite("TimelineViewModel.decodeDaeWoon")
struct TimelineViewModelTests {

    @Test("nil JSON → 빈 배열")
    func decode_nil_empty() {
        let result = TimelineViewModel.decodeDaeWoon(json: nil)
        #expect(result.isEmpty)
    }

    @Test("빈 문자열 → 빈 배열")
    func decode_emptyString_empty() {
        let result = TimelineViewModel.decodeDaeWoon(json: "")
        #expect(result.isEmpty)
    }

    @Test("깨진 JSON → 빈 배열 (try? fallback)")
    func decode_brokenJSON_empty() {
        let result = TimelineViewModel.decodeDaeWoon(json: "{not json")
        #expect(result.isEmpty)
    }

    @Test("올바른 JSON → DaeWoon 배열로 decode")
    func decode_validJSON() throws {
        let input = BirthInput(year: 1990, month: 3, day: 15, hour: 12, minute: 0, gender: .male, nickname: "테스트")
        let result = Manse.calculate(year: input.year, month: input.month, day: input.day, hour: input.hour, gender: input.gender)
        let encoded = try JSONEncoder().encode(result.daeWoon)
        let jsonStr = String(data: encoded, encoding: .utf8)!

        let decoded = TimelineViewModel.decodeDaeWoon(json: jsonStr)
        #expect(decoded.count == result.daeWoon.count)
        #expect(decoded.count > 0)
        #expect(decoded.first?.startAge == result.daeWoon.first?.startAge)
    }
}

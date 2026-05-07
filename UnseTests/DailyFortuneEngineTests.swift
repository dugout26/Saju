import Testing
import Foundation
@testable import Unse

@Suite("매일 운세 엔진")
struct DailyFortuneEngineTests {

    // MARK: - 오행 → 방위

    @Test("木 → 동쪽 / 東 · 木")
    func direction_wood() {
        let d = DailyFortuneEngine.directionLabels(for: .wood)
        #expect(d.korean == "동쪽")
        #expect(d.hanja  == "東 · 木")
    }

    @Test("水 → 북쪽 / 北 · 水")
    func direction_water() {
        let d = DailyFortuneEngine.directionLabels(for: .water)
        #expect(d.korean == "북쪽")
        #expect(d.hanja  == "北 · 水")
    }

    // MARK: - 河圖 숫자

    @Test("水 河圖 = [1, 6]")
    func numbers_water() {
        #expect(DailyFortuneEngine.numbers(for: .water) == [1, 6])
    }

    @Test("木 河圖 = [3, 8]")
    func numbers_wood() {
        #expect(DailyFortuneEngine.numbers(for: .wood) == [3, 8])
    }

    // MARK: - 시간대

    @Test("金 → 申時 15-17시")
    func time_metal() {
        let t = DailyFortuneEngine.timeLabels(for: .metal)
        #expect(t.start == 15)
        #expect(t.end   == 17)
        #expect(t.label == "申時 · 신시")
    }

    // MARK: - 六沖

    @Test("子의 沖은 午")
    func sixOpposite_zi() {
        #expect(DailyFortuneEngine.sixOpposite(of: .子) == .午)
    }

    @Test("巳의 沖은 亥")
    func sixOpposite_si() {
        #expect(DailyFortuneEngine.sixOpposite(of: .巳) == .亥)
    }

    // MARK: - 통합: snapshot 정합성

    @Test("1990-03-15 12시 男 사주 → 水(0개)가 부족 → 北方/[1,6]")
    func snapshot_1990_03_15() {
        let saju = Manse.calculate(year: 1990, month: 3, day: 15, hour: 12, gender: .male).saju
        let snap = DailyFortuneEngine.compute(saju: saju, date: Date())
        // 사주: 庚午 己卯 己卯 庚午 → fiveElements: 木2 火2 土2 金2 水0 → lucky=水
        #expect(snap.luckyElement == .water)
        #expect(snap.luckyDirectionKorean == "북쪽")
        #expect(snap.luckyNumbers == [1, 6])
        #expect(snap.theme == .lavender)
    }
}

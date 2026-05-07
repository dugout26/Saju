import WidgetKit
import SwiftUI
import SwiftData

struct FortuneEntry: TimelineEntry {
    let date: Date
    let luckyColor: LuckyColor
    let luckyNumber: String
    let luckyDirection: String
    let oneLiner: String
    let themeName: String
    let themeHex: String
    let nickname: String
}

struct LuckyColor: Codable {
    let name: String
    let hex: UInt32
}

struct FortuneProvider: TimelineProvider {
    typealias Entry = FortuneEntry

    func placeholder(in context: Context) -> FortuneEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FortuneEntry) -> Void) {
        completion(loadEntry() ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FortuneEntry>) -> Void) {
        let entry = loadEntry() ?? .placeholder

        // Refresh at next midnight
        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func loadEntry() -> FortuneEntry? {
        let defaults = UserDefaults(suiteName: "group.kr.mound.unse")
        guard
            let colorName = defaults?.string(forKey: "luckyColorName"),
            let colorHex = defaults?.object(forKey: "luckyColorHex") as? UInt32,
            let number = defaults?.string(forKey: "luckyNumber"),
            let direction = defaults?.string(forKey: "luckyDirection"),
            let oneLiner = defaults?.string(forKey: "oneLiner"),
            let themeName = defaults?.string(forKey: "themeName"),
            let themeHex = defaults?.string(forKey: "themeHex"),
            let nickname = defaults?.string(forKey: "nickname")
        else { return nil }

        return FortuneEntry(
            date: Date(),
            luckyColor: LuckyColor(name: colorName, hex: colorHex),
            luckyNumber: number,
            luckyDirection: direction,
            oneLiner: oneLiner,
            themeName: themeName,
            themeHex: themeHex,
            nickname: nickname
        )
    }
}

extension FortuneEntry {
    static let placeholder = FortuneEntry(
        date: Date(),
        luckyColor: LuckyColor(name: "라벤더", hex: 0xC9B8F0),
        luckyNumber: "3",
        luckyDirection: "동쪽",
        oneLiner: "차분히 듣는 자세가\n예상 밖의 인연을 부르는 날",
        themeName: "라벤더",
        themeHex: "#C9B8F0",
        nickname: "나"
    )
}

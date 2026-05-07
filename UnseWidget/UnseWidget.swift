import WidgetKit
import SwiftUI

@main
struct UnseWidgetBundle: WidgetBundle {
    var body: some Widget {
        LuckyColorWidget()
        FortuneWidget()
    }
}

// MARK: - Lucky Color Widget (lock screen + home)

struct LuckyColorWidget: Widget {
    let kind = "LuckyColorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FortuneProvider()) { entry in
            LuckyColorWidgetView(entry: entry)
        }
        .configurationDisplayName("행운의 색")
        .description("오늘의 행운 색상과 방향을 한 눈에 확인하세요.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall
        ])
    }
}

struct LuckyColorWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FortuneEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        case .systemSmall:
            HomeSmallView(entry: entry)
        default:
            HomeSmallView(entry: entry)
        }
    }
}

// MARK: - Fortune Widget (home screen medium)

struct FortuneWidget: Widget {
    let kind = "FortuneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FortuneProvider()) { entry in
            HomeMediumView(entry: entry)
        }
        .configurationDisplayName("오늘의 운세")
        .description("오늘의 한 줄 운세와 행운 정보를 확인하세요.")
        .supportedFamilies([.systemMedium])
    }
}

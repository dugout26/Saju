import SwiftUI
import WidgetKit

// MARK: - Lock Screen Accessory (circular / rectangular / inline)

struct LockScreenCircularView: View {
    let entry: FortuneEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Circle()
                    .fill(Color(hex: entry.luckyColor.hex))
                    .frame(width: 20, height: 20)
                Text(entry.luckyColor.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .widgetAccentable()
    }
}

struct LockScreenRectangularView: View {
    let entry: FortuneEntry

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: entry.luckyColor.hex))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("행운의 색")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(entry.luckyColor.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("숫자")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(entry.luckyNumber)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .widgetAccentable()
    }
}

struct LockScreenInlineView: View {
    let entry: FortuneEntry

    var body: some View {
        Text("🎨 \(entry.luckyColor.name)  🧭 \(entry.luckyDirection)  🔢 \(entry.luckyNumber)")
            .font(.system(size: 11, weight: .medium))
            .widgetAccentable()
    }
}

// MARK: - Home Screen Small Widget

struct HomeSmallView: View {
    let entry: FortuneEntry

    var body: some View {
        ZStack {
            Color(hex: 0xFBFAF7)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color(hex: entry.luckyColor.hex).opacity(0.7))
                        .frame(width: 28, height: 28)
                    Spacer()
                    Text("운세")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(entry.luckyColor.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(entry.nickname)님의 오늘 색")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("\(entry.luckyDirection)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: entry.luckyColor.hex))
                    Text("\(entry.luckyNumber)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: entry.luckyColor.hex))
                }
            }
            .padding(14)
        }
        .containerBackground(Color(hex: 0xFBFAF7), for: .widget)
    }
}

// MARK: - Home Screen Medium Widget

struct HomeMediumView: View {
    let entry: FortuneEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: color swatch column
            VStack {
                Circle()
                    .fill(Color(hex: entry.luckyColor.hex).opacity(0.8))
                    .frame(width: 48, height: 48)
                Text(entry.luckyColor.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: entry.luckyColor.hex))
                Text("행운의 색")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxHeight: .infinity)
            .padding(16)
            .background(Color(hex: entry.luckyColor.hex).opacity(0.1))

            // Right: details
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.oneLiner.components(separatedBy: "\n").first ?? entry.oneLiner)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Divider()

                HStack(spacing: 16) {
                    miniStat(label: "방향", value: entry.luckyDirection)
                    miniStat(label: "숫자", value: entry.luckyNumber)
                }

                Spacer()

                Text("\(entry.nickname)님의 오늘 운세")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
        }
        .containerBackground(Color(hex: 0xFBFAF7), for: .widget)
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Color init helper (duplicated for widget target)

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

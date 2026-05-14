import Foundation

// MARK: - 천간 (Heavenly Stems)
enum HeavenlyStem: Int, CaseIterable, Codable, Sendable {
    case 甲 = 0, 乙, 丙, 丁, 戊, 己, 庚, 辛, 壬, 癸

    var character: String { String(describing: self) }

    var korean: String {
        ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"][rawValue]
    }

    var element: Element {
        [.wood, .wood, .fire, .fire, .earth, .earth, .metal, .metal, .water, .water][rawValue]
    }

    var isYang: Bool { rawValue % 2 == 0 }
}

// MARK: - 지지 (Earthly Branches)
enum EarthlyBranch: Int, CaseIterable, Codable, Sendable {
    case 子 = 0, 丑, 寅, 卯, 辰, 巳, 午, 未, 申, 酉, 戌, 亥

    var character: String { String(describing: self) }

    var korean: String {
        ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"][rawValue]
    }

    var element: Element {
        [.water, .earth, .wood, .wood, .earth, .fire, .fire, .earth, .metal, .metal, .earth, .water][rawValue]
    }
}

// MARK: - 오행 (Five Elements)
enum Element: String, CaseIterable, Codable, Sendable {
    case wood  = "木"
    case fire  = "火"
    case earth = "土"
    case metal = "金"
    case water = "水"

    var korean: String {
        switch self {
        case .wood:  return "목"
        case .fire:  return "화"
        case .earth: return "토"
        case .metal: return "금"
        case .water: return "수"
        }
    }
}

// MARK: - 기둥 (Pillar)
struct Pillar: Equatable, Codable, Sendable {
    let stem: HeavenlyStem
    let branch: EarthlyBranch

    var characters: String { stem.character + branch.character }

    // Index in the 60-cycle (육십갑자)
    var cycleIndex: Int {
        for i in 0..<60 where i % 10 == stem.rawValue && i % 12 == branch.rawValue { return i }
        return 0
    }
}

// MARK: - 사주 계산 결과
struct SajuComputed: Equatable, Sendable {
    let year: Pillar
    let month: Pillar
    let day: Pillar
    let hour: Pillar?   // nil when birth time is unknown

    var dayMaster: HeavenlyStem { day.stem }

    var pillars: [Pillar] { [year, month, day] + (hour.map { [$0] } ?? []) }

    var fiveElements: [Element: Int] {
        var counts = Dictionary(uniqueKeysWithValues: Element.allCases.map { ($0, 0) })
        for p in pillars {
            counts[p.stem.element, default: 0]   += 1
            counts[p.branch.element, default: 0] += 1
        }
        return counts
    }

    var dominantElement: Element {
        fiveElements.max(by: { $0.value < $1.value })?.key ?? .earth
    }
}

// MARK: - 대운 (Major Fortune Cycle)
struct DaeWoon: Identifiable, Codable, Sendable {
    var id: Int { startAge }
    let startAge: Int
    let pillar: Pillar
    let startYear: Int
}

// MARK: - 생년월일 입력 데이터
struct BirthInput: Sendable {
    var calendar: BirthCalendar = .solar
    var year: Int = 1996
    var month: Int = 3
    var day: Int = 15
    var hour: Int? = 14
    var minute: Int? = 0
    var gender: Gender = .female
    var nickname: String = ""

    var isValid: Bool {
        (1900...2025).contains(year) &&
        (1...12).contains(month) &&
        (1...31).contains(day)
    }
}

enum BirthCalendar: String, CaseIterable, Codable {
    case solar = "양력"
    case lunar = "음력"
}

enum Gender: String, CaseIterable, Codable {
    case female = "여성"
    case male   = "남성"
}

// MARK: - character → enum 역변환 (SwiftData 캐시 복원용)

extension HeavenlyStem {
    static func from(character: String) -> HeavenlyStem? {
        Self.allCases.first { $0.character == character }
    }
}

extension EarthlyBranch {
    static func from(character: String) -> EarthlyBranch? {
        Self.allCases.first { $0.character == character }
    }
}

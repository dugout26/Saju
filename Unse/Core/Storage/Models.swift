import SwiftData
import Foundation

// MARK: - UserProfile

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var authProvider: String       // "kakao" | "apple"
    var pushTime: Date             // Only hour/minute components are used
    var pushEnabled: Bool
    var subscriptionStatus: String // "free" | "trial" | "premium" | "cancelled"
    var trialStartedAt: Date?
    var subscriptionExpiresAt: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var sajuProfile: SajuProfile?

    init(
        nickname: String,
        authProvider: String,
        pushTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 30))!,
        pushEnabled: Bool = true
    ) {
        self.id = UUID()
        self.nickname = nickname
        self.authProvider = authProvider
        self.pushTime = pushTime
        self.pushEnabled = pushEnabled
        self.subscriptionStatus = "free"
        self.createdAt = Date()
    }

    var subscriptionStatusEnum: SubscriptionStatus {
        SubscriptionStatus(rawValue: subscriptionStatus) ?? .free
    }
}

// MARK: - SajuProfile

@Model
final class SajuProfile {
    @Attribute(.unique) var id: UUID
    var birthCalendar: String      // "solar" | "lunar"
    var birthYear: Int
    var birthMonth: Int
    var birthDay: Int
    var birthHour: Int?
    var birthMinute: Int?
    var gender: String             // "여성" | "남성"

    // Cached computed values (serialized as JSON)
    var yearStem: String;  var yearBranch: String
    var monthStem: String; var monthBranch: String
    var dayStem: String;   var dayBranch: String
    var hourStem: String?; var hourBranch: String?
    var fiveElementsJSON: String   // {"木":1,"火":0,"土":2,"金":3,"水":2}
    var daeWoonJSON: String        // [{startAge, pillar, startYear}]
    var fortuneTheme: String       // "lavender"|"peach"|"mint"

    init(input: BirthInput, saju: SajuComputed, daeWoon: [DaeWoon]) {
        self.id = UUID()
        self.birthCalendar = input.calendar.rawValue
        self.birthYear = input.year
        self.birthMonth = input.month
        self.birthDay = input.day
        self.birthHour = input.hour
        self.birthMinute = input.minute
        self.gender = input.gender.rawValue

        self.yearStem   = saju.year.stem.character
        self.yearBranch = saju.year.branch.character
        self.monthStem   = saju.month.stem.character
        self.monthBranch = saju.month.branch.character
        self.dayStem   = saju.day.stem.character
        self.dayBranch = saju.day.branch.character
        self.hourStem   = saju.hour?.stem.character
        self.hourBranch = saju.hour?.branch.character

        let elDict = Dictionary(uniqueKeysWithValues: saju.fiveElements.map { ($0.key.rawValue, $0.value) })
        self.fiveElementsJSON = (try? String(data: JSONEncoder().encode(elDict), encoding: .utf8)) ?? "{}"

        let encoder = JSONEncoder()
        self.daeWoonJSON = (try? String(data: encoder.encode(daeWoon), encoding: .utf8)) ?? "[]"
        self.fortuneTheme = "lavender"
    }
}

// MARK: - DailyFortune

@Model
final class DailyFortune {
    @Attribute(.unique) var key: String  // "YYYY-MM-DD-userId"
    var date: Date
    var oneLiner: String
    var luckyColorHex: String
    var luckyColorTheme: String
    var luckyDirection: String
    var luckyTimeStart: Date
    var luckyTimeEnd: Date
    var luckyNumbers: [Int]
    var avoid: String
    var generatedAt: Date

    init(key: String, date: Date, oneLiner: String, luckyColorHex: String,
         luckyColorTheme: String, luckyDirection: String,
         luckyTimeStart: Date, luckyTimeEnd: Date,
         luckyNumbers: [Int], avoid: String) {
        self.key = key
        self.date = date
        self.oneLiner = oneLiner
        self.luckyColorHex = luckyColorHex
        self.luckyColorTheme = luckyColorTheme
        self.luckyDirection = luckyDirection
        self.luckyTimeStart = luckyTimeStart
        self.luckyTimeEnd = luckyTimeEnd
        self.luckyNumbers = luckyNumbers
        self.avoid = avoid
        self.generatedAt = Date()
    }
}

// MARK: - ChatMessage

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: String   // "user" | "assistant"
    var content: String
    var createdAt: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}

// MARK: - SajuReading

@Model
final class SajuReading {
    @Attribute(.unique) var key: String  // "userId-stage"
    var stage: Int                       // 1~5
    var content: String
    var generatedAt: Date

    init(key: String, stage: Int, content: String) {
        self.key = key
        self.stage = stage
        self.content = content
        self.generatedAt = Date()
    }
}

// MARK: - Supporting enums

enum SubscriptionStatus: String {
    case free, trial, premium, cancelled
}

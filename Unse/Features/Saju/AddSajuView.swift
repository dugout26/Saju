import SwiftUI
import SwiftData

/// 추가 사주 등록 또는 기존 사주 편집. 1일 1회 변경 제한.
struct AddSajuView: View {
    let user: UserProfile
    var editingSaju: SajuProfile? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var relation = "가족"
    @State private var year = 1996
    @State private var month = 3
    @State private var day = 15
    @State private var hour = 12
    @State private var hourUnknown = false
    @State private var calendar: BirthCalendar = .solar
    @State private var gender: Gender = .female
    @State private var errorMessage: String?

    private let relations = ["가족", "친구", "연인", "기타"]

    private var isEditing: Bool { editingSaju != nil }
    private var isOwner: Bool { editingSaju?.relation == "본인" }

    /// 마지막 변경 후 24시간 안 지났으면 변경 차단
    private var canModify: Bool {
        guard let saju = editingSaju else { return true }
        return Date().timeIntervalSince(saju.lastModifiedAt) >= 24 * 3600
    }

    var body: some View {
        NavigationStack {
            Form {
                if isEditing && !canModify {
                    Section {
                        Label("하루에 한 번만 변경할 수 있어요", systemImage: "clock.badge.exclamationmark")
                            .font(.pretendard(13))
                            .foregroundStyle(.orange)
                    }
                }

                Section("이름") {
                    TextField("예: 엄마, 이수정", text: $displayName)
                }

                if !isOwner {
                    Section("관계") {
                        Picker("관계", selection: $relation) {
                            ForEach(relations, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }

                Section("출생정보") {
                    Picker("달력", selection: $calendar) {
                        ForEach(BirthCalendar.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Picker("성별", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Stepper("년 \(year)", value: $year, in: 1900...2025)
                    Stepper("월 \(month)", value: $month, in: 1...12)
                    Stepper("일 \(day)", value: $day, in: 1...31)
                    Toggle("시간 모름", isOn: $hourUnknown)
                    if !hourUnknown {
                        Stepper("시 \(hour)", value: $hour, in: 0...23)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.pretendard(12))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "정보 편집" : "인원 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") { save() }
                        .disabled(!canModify || displayName.isEmpty)
                }
            }
            .onAppear { loadIfEditing() }
        }
    }

    private func loadIfEditing() {
        guard let saju = editingSaju else { return }
        displayName = saju.displayName
        relation = saju.relation == "본인" ? "본인" : saju.relation
        year = saju.birthYear
        month = saju.birthMonth
        day = saju.birthDay
        hour = saju.birthHour ?? 12
        hourUnknown = saju.birthHour == nil
        calendar = BirthCalendar(rawValue: saju.birthCalendar) ?? .solar
        gender = Gender(rawValue: saju.gender) ?? .female
    }

    private func save() {
        let input = BirthInput(
            calendar: calendar,
            year: year, month: month, day: day,
            hour: hourUnknown ? nil : hour,
            minute: 0,
            gender: gender,
            nickname: displayName
        )
        let result = Manse.calculate(
            year: input.year, month: input.month, day: input.day,
            hour: input.hour, minute: input.minute,
            calendar: input.calendar, gender: input.gender
        )

        if let existing = editingSaju {
            existing.displayName = displayName
            existing.relation = isOwner ? "본인" : relation
            existing.birthCalendar = input.calendar.rawValue
            existing.birthYear = year
            existing.birthMonth = month
            existing.birthDay = day
            existing.birthHour = input.hour
            existing.birthMinute = 0
            existing.gender = gender.rawValue
            existing.yearStem = result.saju.year.stem.character
            existing.yearBranch = result.saju.year.branch.character
            existing.monthStem = result.saju.month.stem.character
            existing.monthBranch = result.saju.month.branch.character
            existing.dayStem = result.saju.day.stem.character
            existing.dayBranch = result.saju.day.branch.character
            existing.hourStem = result.saju.hour?.stem.character
            existing.hourBranch = result.saju.hour?.branch.character
            existing.lastModifiedAt = Date()
        } else {
            let new = SajuProfile(
                input: input, saju: result.saju, daeWoon: result.daeWoon,
                displayName: displayName, relation: relation
            )
            user.savedSajus.append(new)
            modelContext.insert(new)
        }
        try? modelContext.save()
        dismiss()
    }
}

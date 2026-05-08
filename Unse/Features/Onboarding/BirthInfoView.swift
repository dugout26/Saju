import SwiftUI
import SwiftData
import Observation

// MARK: - BirthInfoViewModel

@Observable
@MainActor
final class BirthInfoViewModel {
    var input = BirthInput()
    var isLoading = false
    var errorMessage: String?

    var yearText: String { String(input.year)  }
    var monthText: String { String(format: "%02d", input.month) }
    var dayText: String { String(format: "%02d", input.day)   }
    var hourText: String { input.hour.map { String(format: "%02d", $0) } ?? "" }
    var minText: String { input.minute.map { String(format: "%02d", $0) } ?? "" }

    var formIsValid: Bool { input.isValid && !input.nickname.isEmpty }

    func compute() -> (saju: SajuComputed, daeWoon: [DaeWoon]) {
        Manse.calculate(
            year: input.year, month: input.month, day: input.day,
            hour: input.hour, minute: input.minute,
            calendar: input.calendar, gender: input.gender
        )
    }
}

// MARK: - BirthInfoView

struct BirthInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = BirthInfoViewModel()
    @State private var showAnalyzing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                calendarField
                birthdateField
                timeField
                genderField
                nicknameField
                footerButtons
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("출생 정보")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showAnalyzing) {
            AnalyzingView(vm: vm)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("정확할수록\n풀이가 깊어져요")
                .font(.serifKR(24, .semibold))
                .foregroundStyle(.ink1)
                .lineSpacing(4)
            Text("시간을 모르시면 '시 모름'을 체크하세요")
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
        }
        .padding(.top, Spacing.md)
    }

    private var calendarField: some View {
        FormField(label: "달력 기준") {
            Segment(options: BirthCalendar.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { vm.input.calendar.rawValue },
                        set: { v in vm.input.calendar = BirthCalendar(rawValue: v) ?? .solar }
                    ))
        }
    }

    private var birthdateField: some View {
        FormField(label: "생년월일") {
            HStack(spacing: 8) {
                NumberInput(value: $vm.input.year, suffix: "년", range: 1900...2025, flex: 1.4)
                NumberInput(value: $vm.input.month, suffix: "월", range: 1...12)
                NumberInput(value: $vm.input.day, suffix: "일", range: 1...31)
            }
        }
    }

    private var timeField: some View {
        FormField(label: "태어난 시간") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    OptionalNumberInput(
                        value: Binding(
                            get: { vm.input.hour },
                            set: { vm.input.hour = $0 }
                        ),
                        suffix: "시", range: 0...23,
                        disabled: vm.input.hour == nil
                    )
                    OptionalNumberInput(
                        value: Binding(
                            get: { vm.input.minute },
                            set: { vm.input.minute = $0 }
                        ),
                        suffix: "분", range: 0...59,
                        disabled: vm.input.hour == nil
                    )
                }
                CheckBox(label: "시 모름", isOn: Binding(
                    get: { vm.input.hour == nil },
                    set: { unknown in vm.input.hour = unknown ? nil : 12; vm.input.minute = unknown ? nil : 0 }
                ))
            }
        }
    }

    private var genderField: some View {
        FormField(label: "성별") {
            Segment(options: Gender.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { vm.input.gender.rawValue },
                        set: { v in vm.input.gender = Gender(rawValue: v) ?? .female }
                    ))
        }
    }

    private var nicknameField: some View {
        FormField(label: "닉네임") {
            TextField("앱에서 부를 이름", text: $vm.input.nickname)
                .font(.pretendard(16))
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.line, lineWidth: 1))
        }
    }

    private var footerButtons: some View {
        VStack(spacing: Spacing.sm) {
            PrimaryButton(title: "내 사주 보기") {
                showAnalyzing = true
            }
            .disabled(!vm.formIsValid)
            .opacity(vm.formIsValid ? 1 : 0.5)

            Text("입력하신 정보는 사주 풀이에만 사용되며\n외부에 공유되지 않습니다.")
                .font(.pretendard(11))
                .foregroundStyle(.ink4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.sm)
        }
    }
}

// MARK: - FormField

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.pretendard(12, .semibold))
                .foregroundStyle(.ink2)
            content
        }
    }
}

// MARK: - NumberInput

struct NumberInput: View {
    @Binding var value: Int
    let suffix: String
    let range: ClosedRange<Int>
    var flex: CGFloat = 1

    @State private var text: String = ""

    var body: some View {
        HStack {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .font(.pretendard(16))
                .onChange(of: text) { _, new in
                    if let n = Int(new), range.contains(n) { value = n }
                }
                .onAppear { text = String(value) }
            Text(suffix).font(.pretendard(14)).foregroundStyle(.ink3)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.line, lineWidth: 1))
    }
}

// MARK: - OptionalNumberInput

struct OptionalNumberInput: View {
    @Binding var value: Int?
    let suffix: String
    let range: ClosedRange<Int>
    let disabled: Bool

    @State private var text: String = ""

    var body: some View {
        HStack {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .font(.pretendard(16))
                .disabled(disabled)
                .onChange(of: text) { _, new in
                    if let n = Int(new), range.contains(n) { value = n }
                }
                .onAppear { text = value.map(String.init) ?? "" }
            Text(suffix).font(.pretendard(14)).foregroundStyle(.ink3)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(disabled ? Color(hex: 0xF4F2EC) : Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.line, lineWidth: 1))
        .opacity(disabled ? 0.5 : 1)
    }
}

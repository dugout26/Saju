import SwiftUI
import SwiftData
import FirebaseCrashlytics

/// 본인 사주 정보 편집. 저장 시 SwiftData + Supabase 양쪽 동기화.
/// 출생 정보 변경 제한: Free 30일 1회 / PRO 1일 1회. 닉네임만 변경 시엔 무제한.
struct EditSajuView: View {
    let user: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var sub
    @State private var vm = BirthInfoViewModel()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showRecomputeConfirm = false
    @State private var showLimitAlert = false
    @State private var limitMessage = ""
    @State private var showRecomputing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                calendarField
                birthdateField
                timeField
                genderField
                nicknameField
                if let errorMessage {
                    Text(errorMessage)
                        .font(.pretendard(12))
                        .foregroundStyle(.red.opacity(0.8))
                }
                saveButton
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("사주 정보 편집")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prefill() }
        .alert("사주를 다시 받으시겠습니까?", isPresented: $showRecomputeConfirm) {
            Button("아니오", role: .cancel) {}
            Button("예", role: .destructive) { performSave(recomputeSaju: true) }
        } message: {
            Text("출생 정보가 변경되어 사주가 다시 계산되고 풀이가 초기화됩니다.")
        }
        .alert("변경 불가", isPresented: $showLimitAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(limitMessage)
        }
        .fullScreenCover(isPresented: $showRecomputing) {
            AnalyzingView(
                vm: vm,
                onSave: { saju, daeWoon in
                    // SwiftData 업데이트는 performSave에서 이미 완료. Supabase 동기화 + 캐시 무효화는 Service에 위임.
                    try await SajuEditService.commitRecompute(
                        input: vm.input, saju: saju, daeWoon: daeWoon
                    )
                },
                onComplete: {
                    showRecomputing = false
                    dismiss()
                },
                title: "사주를 다시 풀고 있어요"
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("출생 정보를\n수정할 수 있어요")
                .font(.serifKR(22, .semibold))
                .foregroundStyle(.ink1)
                .lineSpacing(4)
            Text("저장하면 사주가 다시 계산되고 풀이도 갱신됩니다")
                .font(.pretendard(12))
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
                NumberInput(value: $vm.input.year, suffix: "년", range: 1900...currentYear, flex: 1.4)
                NumberInput(value: $vm.input.month, suffix: "월", range: 1...12)
                NumberInput(value: $vm.input.day, suffix: "일", range: 1...31)
            }
        }
    }

    /// 출생 연도 상한 — 매년 자동 업데이트
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
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
                .padding(.horizontal, Spacing.formField)
                .frame(height: 52)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.input))
                .overlay(RoundedRectangle(cornerRadius: Radius.input).strokeBorder(Color.line, lineWidth: 1))
        }
    }

    private var saveButton: some View {
        PrimaryButton(title: isSaving ? "저장 중..." : "저장") { save() }
            .disabled(!vm.formIsValid || isSaving)
            .opacity(vm.formIsValid && !isSaving ? 1 : 0.5)
    }

    // MARK: - Actions

    private func prefill() {
        vm.input.nickname = user.nickname
        guard let saju = user.sajuProfile else { return }
        vm.input.calendar = BirthCalendar(rawValue: saju.birthCalendar) ?? .solar
        vm.input.year = saju.birthYear
        vm.input.month = saju.birthMonth
        vm.input.day = saju.birthDay
        vm.input.hour = saju.birthHour
        vm.input.minute = saju.birthMinute
        vm.input.gender = Gender(rawValue: saju.gender) ?? .female
    }

    /// 출생 필드(생년월일·시·달력·성별)가 prefill 값과 다른지
    private var birthFieldsChanged: Bool {
        guard let saju = user.sajuProfile else { return true }
        return vm.input.calendar.rawValue != saju.birthCalendar
            || vm.input.year != saju.birthYear
            || vm.input.month != saju.birthMonth
            || vm.input.day != saju.birthDay
            || vm.input.hour != saju.birthHour
            || vm.input.minute != saju.birthMinute
            || vm.input.gender.rawValue != saju.gender
    }

    private func save() {
        errorMessage = nil

        // 닉네임만 변경 시 — 즉시 저장 (사주 재계산 X)
        guard birthFieldsChanged else {
            performSave(recomputeSaju: false)
            return
        }

        // 출생 정보 변경 — 권한 체크
        if sub.isPremium {
            // PRO: 1일 1회 — KST 자정 기준 (사용자 인지의 "하루"와 일치).
            if let last = user.sajuProfile?.lastModifiedAt,
               user.sajuModifiedCount > 0,
               !SajuEditService.canEditSajuToday(lastModified: last) {
                limitMessage = "사주 변경은 하루에 한 번만 가능해요. 내일 다시 시도해 주세요."
                showLimitAlert = true
                return
            }
        } else {
            // Free: 30일 1회 — 출생 정보 실수 회복 여지를 주되 PRO와 차별화.
            if let last = user.sajuProfile?.lastModifiedAt,
               user.sajuModifiedCount > 0 {
                let status = SajuEditService.freeMonthlyEditStatus(lastModified: last)
                if !status.allowed {
                    limitMessage = "무료 버전은 30일에 한 번 변경 가능해요.\n약 \(status.daysRemaining)일 후 다시 시도해 주세요.\nPRO는 매일 변경 가능합니다."
                    showLimitAlert = true
                    return
                }
            }
        }

        // confirm
        showRecomputeConfirm = true
    }

    private func performSave(recomputeSaju: Bool) {
        isSaving = true
        let input = vm.input

        if recomputeSaju {
            // 출생정보 변경 — 로컬 SwiftData 즉시 저장 + 캐시 무효화. Supabase는 AnalyzingView가 처리.
            do {
                let result = vm.compute()
                try SajuEditService.recomputeAndSaveLocally(
                    input: input, result: result, user: user, modelContext: modelContext
                )
                showRecomputing = true
            } catch {
                Crashlytics.crashlytics().record(error: error)
                errorMessage = "저장 중 오류가 발생했어요. 다시 시도해주세요.\n(\(error.localizedDescription))"
            }
            isSaving = false
            return
        }

        // 닉네임만 변경 — 로컬 + 원격 동기화 후 dismiss.
        Task { @MainActor in
            do {
                try await SajuEditService.updateNickname(
                    input.nickname, user: user, modelContext: modelContext
                )
                dismiss()
            } catch {
                Crashlytics.crashlytics().record(error: error)
                errorMessage = "저장 실패. 다시 시도해주세요.\n(\(error.localizedDescription))"
            }
            isSaving = false
        }
    }
}

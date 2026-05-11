import SwiftUI
import SwiftData

/// 본인 사주 정보 편집. 도메인 로직 + 권한 검사는 EditSajuViewModel에 위임.
/// 출생 정보 변경 제한: Free 30일 1회 / PRO 1일 1회. 닉네임만 변경 시엔 무제한.
struct EditSajuView: View {
    let user: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var sub
    @State private var vm: EditSajuViewModel

    init(user: UserProfile) {
        self.user = user
        _vm = State(initialValue: EditSajuViewModel(user: user))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                calendarField
                birthdateField
                timeField
                genderField
                nicknameField
                if let errorMessage = vm.errorMessage {
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
        .alert("사주를 다시 받으시겠습니까?", isPresented: $vm.showRecomputeConfirm) {
            Button("아니오", role: .cancel) {}
            Button("예", role: .destructive) {
                vm.confirmRecompute(modelContext: modelContext)
            }
        } message: {
            Text("출생 정보가 변경되어 사주가 다시 계산되고 풀이가 초기화됩니다.")
        }
        .alert("변경 불가", isPresented: $vm.showLimitAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(vm.limitMessage)
        }
        .fullScreenCover(isPresented: $vm.showRecomputing) {
            AnalyzingView(
                vm: vm.birthVM,
                onSave: { saju, daeWoon in
                    // SwiftData 업데이트는 confirmRecompute에서 이미 완료. Supabase 동기화 + 캐시 무효화는 Service에 위임.
                    try await SajuEditService.commitRecompute(
                        input: vm.birthVM.input, saju: saju, daeWoon: daeWoon
                    )
                },
                onComplete: {
                    vm.showRecomputing = false
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
                        get: { vm.birthVM.input.calendar.rawValue },
                        set: { v in vm.birthVM.input.calendar = BirthCalendar(rawValue: v) ?? .solar }
                    ))
        }
    }

    private var birthdateField: some View {
        FormField(label: "생년월일") {
            HStack(spacing: 8) {
                NumberInput(value: $vm.birthVM.input.year, suffix: "년", range: 1900...currentYear, flex: 1.4)
                NumberInput(value: $vm.birthVM.input.month, suffix: "월", range: 1...12)
                NumberInput(value: $vm.birthVM.input.day, suffix: "일", range: 1...31)
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
                            get: { vm.birthVM.input.hour },
                            set: { vm.birthVM.input.hour = $0 }
                        ),
                        suffix: "시", range: 0...23,
                        disabled: vm.birthVM.input.hour == nil
                    )
                    OptionalNumberInput(
                        value: Binding(
                            get: { vm.birthVM.input.minute },
                            set: { vm.birthVM.input.minute = $0 }
                        ),
                        suffix: "분", range: 0...59,
                        disabled: vm.birthVM.input.hour == nil
                    )
                }
                CheckBox(label: "시 모름", isOn: Binding(
                    get: { vm.birthVM.input.hour == nil },
                    set: { unknown in vm.birthVM.input.hour = unknown ? nil : 12; vm.birthVM.input.minute = unknown ? nil : 0 }
                ))
            }
        }
    }

    private var genderField: some View {
        FormField(label: "성별") {
            Segment(options: Gender.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { vm.birthVM.input.gender.rawValue },
                        set: { v in vm.birthVM.input.gender = Gender(rawValue: v) ?? .female }
                    ))
        }
    }

    private var nicknameField: some View {
        FormField(label: "닉네임") {
            TextField("앱에서 부를 이름", text: $vm.birthVM.input.nickname)
                .font(.pretendard(16))
                .padding(.horizontal, Spacing.formField)
                .frame(height: 52)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.input))
                .overlay(RoundedRectangle(cornerRadius: Radius.input).strokeBorder(Color.line, lineWidth: 1))
        }
    }

    private var saveButton: some View {
        PrimaryButton(title: vm.isSaving ? "저장 중..." : "저장") {
            Task {
                let dismissable = await vm.save(isPremium: sub.isPremium, modelContext: modelContext)
                if dismissable { dismiss() }
            }
        }
        .disabled(!vm.birthVM.formIsValid || vm.isSaving)
        .opacity(vm.birthVM.formIsValid && !vm.isSaving ? 1 : 0.5)
    }
}

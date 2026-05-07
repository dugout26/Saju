import SwiftUI
import SwiftData

/// 본인 사주 정보 편집. 저장 시 SwiftData + Supabase 양쪽 동기화.
/// 출생 정보 변경 제한: Free 평생 1회 / PRO 1일 1회. 닉네임만 변경 시엔 무제한.
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
                    // SwiftData 업데이트는 EditSajuView.performSave에서 이미 완료.
                    // 서버 캐시 무효화 (옛 풀이가 새 사주에 맞지 않으니까)
                    if let userId = try? await SupabaseManager.shared.auth.session.user.id {
                        _ = try? await SupabaseManager.shared
                            .from("saju_readings")
                            .delete()
                            .eq("user_id", value: userId)
                            .execute()
                        _ = try? await SupabaseManager.shared
                            .from("daily_fortunes")
                            .delete()
                            .eq("user_id", value: userId)
                            .execute()
                    }
                    // Supabase 사주 동기화
                    try await SupabaseAuthManager.upsertSajuProfile(
                        input: vm.input, saju: saju, daeWoon: daeWoon
                    )
                    try await SupabaseAuthManager.updateNickname(vm.input.nickname)
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
                NumberInput(value: $vm.input.year,  suffix: "년", range: 1900...2025, flex: 1.4)
                NumberInput(value: $vm.input.month, suffix: "월", range: 1...12)
                NumberInput(value: $vm.input.day,   suffix: "일", range: 1...31)
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
            // PRO: 1일 1회 (마지막 변경 후 24h)
            if let last = user.sajuProfile?.lastModifiedAt,
               user.sajuModifiedCount > 0,
               Date().timeIntervalSince(last) < 24 * 3600 {
                limitMessage = "사주 변경은 하루에 한 번만 가능해요. 24시간 후 다시 시도해 주세요."
                showLimitAlert = true
                return
            }
        } else {
            // Free: 평생 1회
            if user.sajuModifiedCount >= 1 {
                limitMessage = "무료 버전은 더 이상 변경할 수 없습니다.\nPRO로 업그레이드하면 하루 1회 변경 가능해요."
                showLimitAlert = true
                return
            }
        }

        // confirm
        showRecomputeConfirm = true
    }

    private func performSave(recomputeSaju: Bool) {
        isSaving = true
        let result = vm.compute()
        let input = vm.input

        // SwiftData
        user.nickname = input.nickname

        if recomputeSaju, let saju = user.sajuProfile {
            saju.birthCalendar = input.calendar.rawValue
            saju.birthYear = input.year
            saju.birthMonth = input.month
            saju.birthDay = input.day
            saju.birthHour = input.hour
            saju.birthMinute = input.minute
            saju.gender = input.gender.rawValue
            saju.yearStem = result.saju.year.stem.character
            saju.yearBranch = result.saju.year.branch.character
            saju.monthStem = result.saju.month.stem.character
            saju.monthBranch = result.saju.month.branch.character
            saju.dayStem = result.saju.day.stem.character
            saju.dayBranch = result.saju.day.branch.character
            saju.hourStem = result.saju.hour?.stem.character
            saju.hourBranch = result.saju.hour?.branch.character

            let elDict = Dictionary(uniqueKeysWithValues: result.saju.fiveElements.map { ($0.key.rawValue, $0.value) })
            saju.fiveElementsJSON = (try? String(data: JSONEncoder().encode(elDict), encoding: .utf8)) ?? "{}"
            saju.daeWoonJSON = (try? String(data: JSONEncoder().encode(result.daeWoon), encoding: .utf8)) ?? "[]"
            saju.lastModifiedAt = Date()

            user.sajuModifiedCount += 1

            // SajuReading 캐시 무효화 — 풀이가 새 사주에 맞게 다시 생성되도록
            let userIdPrefix = user.id.uuidString
            let descriptor = FetchDescriptor<SajuReading>(
                predicate: #Predicate { $0.key.starts(with: userIdPrefix) }
            )
            if let stale = try? modelContext.fetch(descriptor) {
                for row in stale { modelContext.delete(row) }
            }
        }
        try? modelContext.save()

        // 재계산 케이스: AnalyzingView가 분석 모션 + Supabase upsert + saju-reading prefetch 처리.
        if recomputeSaju {
            showRecomputing = true
            isSaving = false
            return
        }

        // 닉네임만 변경: 동기 동기화 후 dismiss.
        Task { @MainActor in
            do {
                try await SupabaseAuthManager.updateNickname(input.nickname)
                dismiss()
            } catch {
                errorMessage = "서버 동기화 실패. 로컬엔 저장됐어요.\n(\(error.localizedDescription))"
            }
            isSaving = false
        }
    }
}

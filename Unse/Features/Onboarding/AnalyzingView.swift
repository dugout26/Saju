import SwiftUI
import SwiftData

struct AnalyzingView: View {
    let vm: BirthInfoViewModel
    /// 외부 저장 로직. 제공 시 default(UserProfile insert) 대신 호출 — edit 흐름에서 사용.
    var onSave: ((SajuComputed, [DaeWoon]) async throws -> Void)? = nil
    /// 분석 완료 시 호출. 제공 안 하면 RootView의 @Query 자동 swap에 위임 (onboarding).
    var onComplete: (() -> Void)? = nil
    /// 화면 제목. edit 흐름에선 "사주를 다시 풀고 있어요"로.
    var title: String = "사주를 풀고 있어요"

    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var floating = false
    @State private var computedResult: (saju: SajuComputed, daeWoon: [DaeWoon])?
    @State private var errorMessage: String?

    private let steps = [
        "생년월일을 천간지지로 변환",
        "오행 균형 분석",
        "용신 추출",
        "대운 흐름 계산",
    ]

    private let chars: [String] = ["壬","戊","己","癸","寅","申","卯","酉"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.lavenderSoft, .bg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                floatingChars
                    .padding(.bottom, 36)

                Text(title)
                    .font(.serifKR(22, .semibold))
                    .foregroundStyle(.ink1)

                stepList
                    .padding(.top, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarBackButtonHidden()
        .alert("저장 중 오류가 발생했어요", isPresented: .constant(errorMessage != nil), actions: {
            Button("다시 시도") {
                errorMessage = nil
                Task { await runAnimation() }
            }
        }, message: {
            Text(errorMessage ?? "")
        })
        .task { await runAnimation() }
    }

    private var floatingChars: some View {
        HStack(spacing: 8) {
            ForEach(chars.indices, id: \.self) { i in
                Text(chars[i])
                    .font(.serifKR(16, .medium))
                    .foregroundStyle(.ink1)
                    .frame(width: 30, height: 30)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .lavenderDeep.opacity(0.12), radius: 14, y: 4)
                    .offset(y: floating ? -6 : 0)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.12),
                        value: floating
                    )
            }
        }
        .onAppear { floating = true }
    }

    private var stepList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(steps.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    stepDot(index: i)
                    Text(steps[i])
                        .font(.pretendard(13))
                        .foregroundStyle(.ink2)
                }
                .opacity(i <= step ? 1 : 0.25)
                .animation(.easeInOut(duration: 0.3).delay(Double(i) * 0.05), value: step)
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
    }

    private func stepDot(index i: Int) -> some View {
        ZStack {
            if i < step {
                Circle().fill(Color.lavenderDeep)
                    .frame(width: 16, height: 16)
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            } else if i == step {
                Circle().stroke(Color.lavenderDeep, lineWidth: 2)
                    .frame(width: 16, height: 16)
            } else {
                Circle().fill(Color(hex: 0xE5E3DC))
                    .frame(width: 16, height: 16)
            }
        }
    }

    private func runAnimation() async {
        let result = vm.compute()
        computedResult = result

        // 저장은 animation과 병렬로 시작 (사용자는 4.4s 동안 step animation 봄)
        let saveTask = Task { try await performSave(result: result) }

        for i in steps.indices {
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation { step = i + 1 }
        }

        // 저장 완료 대기. 실패 시 alert 표시 + 진행 중단.
        do {
            try await saveTask.value
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // 저장 끝났으면 saju-reading 1, 2단계 백그라운드 prefetch.
        // 결과 무시 — 응답이 saju_readings에 캐시되므로 SajuResultView 진입 시 자동 hit.
        let nickname = vm.input.nickname
        let computed = result.saju
        Task {
            async let stage1 = APIClient.shared.fetchSajuReading(stage: 1, saju: computed, nickname: nickname)
            async let stage2 = APIClient.shared.fetchSajuReading(stage: 2, saju: computed, nickname: nickname)
            _ = try? await (stage1, stage2)
        }

        try? await Task.sleep(for: .seconds(0.5))

        // edit 흐름: onComplete가 있으면 호출 (외부에서 dismiss 처리)
        // onboarding 흐름: onComplete 없음. RootView @Query가 새 UserProfile 감지해서 자동 swap
        onComplete?()
    }

    private func performSave(result: (saju: SajuComputed, daeWoon: [DaeWoon])) async throws {
        // edit 흐름: 외부 onSave가 SwiftData 업데이트 + Supabase 동기화 + 캐시 무효화 처리
        if let onSave {
            try await onSave(result.saju, result.daeWoon)
            return
        }

        // onboarding 흐름 (default): 새 user 생성
        try await SupabaseAuthManager.updateNickname(vm.input.nickname)
        try await SupabaseAuthManager.upsertSajuProfile(
            input: vm.input,
            saju: result.saju,
            daeWoon: result.daeWoon
        )

        let user = UserProfile(nickname: vm.input.nickname, authProvider: "apple")
        let profile = SajuProfile(
            input: vm.input, saju: result.saju, daeWoon: result.daeWoon,
            displayName: vm.input.nickname, relation: "본인"
        )
        user.sajuProfile = profile
        modelContext.insert(user)
        try? modelContext.save()

        _ = await PushManager.shared.requestPermission()
    }
}

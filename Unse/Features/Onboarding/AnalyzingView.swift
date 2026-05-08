import SwiftUI
import SwiftData

struct AnalyzingView: View {
    let vm: BirthInfoViewModel
    /// 외부 저장 로직. 제공 시 default(UserProfile insert) 대신 호출 — edit 흐름에서 사용.
    var onSave: ((SajuComputed, [DaeWoon]) async throws -> Void)?
    /// 분석 완료 시 호출. 제공 안 하면 RootView의 @Query 자동 swap에 위임 (onboarding).
    var onComplete: (() -> Void)?
    /// 화면 제목. edit 흐름에선 "사주를 다시 풀고 있어요"로.
    var title: String = "사주를 풀고 있어요"

    @Environment(\.modelContext) private var modelContext
    @State private var avm = AnalyzingViewModel()
    @State private var floating = false

    private let steps = [
        "생년월일을 천간지지로 변환",
        "오행 균형 분석",
        "용신 추출",
        "대운 흐름 계산"
    ]

    private let chars: [String] = ["壬", "戊", "己", "癸", "寅", "申", "卯", "酉"]

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
        .alert("저장 중 오류가 발생했어요", isPresented: Binding(
            get: { avm.errorMessage != nil },
            set: { if !$0 { avm.errorMessage = nil } }
        )) {
            Button("다시 시도") {
                avm.errorMessage = nil
                Task { await runAnimation() }
            }
        } message: {
            Text(avm.errorMessage ?? "")
        }
        .task { await runAnimation() }
    }

    private func runAnimation() async {
        await avm.runAnimation(
            birthVM: vm,
            stepCount: steps.count,
            onSave: onSave,
            onComplete: onComplete,
            modelContext: modelContext
        )
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
                .opacity(i <= avm.step ? 1 : 0.25)
                .animation(.easeInOut(duration: 0.3).delay(Double(i) * 0.05), value: avm.step)
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
    }

    private func stepDot(index i: Int) -> some View {
        ZStack {
            if i < avm.step {
                Circle().fill(Color.lavenderDeep)
                    .frame(width: 16, height: 16)
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            } else if i == avm.step {
                Circle().stroke(Color.lavenderDeep, lineWidth: 2)
                    .frame(width: 16, height: 16)
            } else {
                Circle().fill(Color(hex: 0xE5E3DC))
                    .frame(width: 16, height: 16)
            }
        }
    }
}

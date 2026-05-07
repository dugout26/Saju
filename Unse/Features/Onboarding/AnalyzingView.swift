import SwiftUI
import SwiftData

struct AnalyzingView: View {
    let vm: BirthInfoViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var floating = false
    @State private var showResult = false
    @State private var computedResult: (saju: SajuComputed, daeWoon: [DaeWoon])?

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

                Text("사주를 풀고 있어요")
                    .font(.serifKR(22, .semibold))
                    .foregroundStyle(.ink1)

                stepList
                    .padding(.top, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $showResult) {
            if let r = computedResult {
                SajuResultView(
                    saju: r.saju,
                    daeWoon: r.daeWoon,
                    nickname: vm.input.nickname
                )
            }
        }
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

        for i in steps.indices {
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation { step = i + 1 }
        }

        try? await Task.sleep(for: .seconds(0.5))

        // Save to SwiftData
        let profile = SajuProfile(input: vm.input, saju: result.saju, daeWoon: result.daeWoon)
        modelContext.insert(profile)
        try? modelContext.save()

        showResult = true
    }
}

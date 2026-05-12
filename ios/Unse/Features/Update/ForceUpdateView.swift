import SwiftUI

/// 강제 업데이트 오버레이. dismiss 불가 — "업데이트" 버튼만 가능.
struct ForceUpdateView: View {
    let message: String
    let storeURL: String?

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.lavenderDeep)

                VStack(spacing: 12) {
                    Text("새 버전이 있어요")
                        .font(.serifKR(24, .semibold))
                        .foregroundStyle(.ink1)
                    Text(message)
                        .font(.pretendard(14))
                        .foregroundStyle(.ink2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                Spacer()

                PrimaryButton(title: "업데이트하기", color: .lavenderDeep) {
                    if let urlStr = storeURL, let url = URL(string: urlStr) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

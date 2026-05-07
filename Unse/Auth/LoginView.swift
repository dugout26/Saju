import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @State private var showBirthInfo = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("시작하기")
                    .font(.serifKR(28, .semibold))
                    .foregroundStyle(.ink1)
                Text("나만의 사주 분석을 위해\n간편 로그인이 필요해요")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            if isAuthenticating {
                ProgressView()
                    .padding(.bottom, 8)
            }

            SignInWithAppleButton(.signIn) { _ in
                // 실제 호출은 onCompletion 대신 SupabaseAuthManager에서 처리 (nonce 필요)
            } onCompletion: { _ in
                // unused
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                Button(action: signInWithApple) {
                    Color.clear
                }
            }
            .disabled(isAuthenticating)

            if let errorMessage {
                Text(errorMessage)
                    .font(.pretendard(12))
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Text("로그인 시 이용약관 및 개인정보처리방침에 동의합니다")
                .font(.pretendard(11))
                .foregroundStyle(.ink3)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(Color.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $showBirthInfo) {
            BirthInfoView()
        }
    }

    private func signInWithApple() {
        isAuthenticating = true
        errorMessage = nil
        Task {
            do {
                _ = try await SupabaseAuthManager.signInWithApple()
                showBirthInfo = true
            } catch {
                errorMessage = "로그인에 실패했어요. 다시 시도해 주세요.\n(\(error.localizedDescription))"
            }
            isAuthenticating = false
        }
    }
}

import SwiftUI
import SwiftData
import FirebaseCrashlytics

@MainActor
struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
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

            Button(action: signInWithKakao) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("카카오로 시작하기")
                        .font(.pretendard(20, .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.black)
                .background(Color(hex: 0xFEE500))      // 카카오 brand 컬러
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isAuthenticating)

            // 커스텀 Apple 버튼 — Kakao와 동일한 Pretendard 적용 위해 SignInWithAppleButton 대신 사용.
            // Apple HIG 준수: `applelogo` 공식 SF Symbol + 표준 localized 텍스트("Apple로 계속하기" =
            // "Continue with Apple"의 공식 한국어 번역) + 검정 배경. "Apple로 시작하기"는 비표준이라 금지.
            // 실제 auth는 AppleAuthManager의 ASAuthorizationController가 처리 (signInWithApple 진입점).
            Button(action: signInWithApple) {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20, weight: .bold))
                    Text("Apple로 계속하기")
                        .font(.pretendard(20, .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
        Task { await performSignIn { try await SupabaseAuthManager.signInWithApple() } }
    }

    private func signInWithKakao() {
        Task { await performSignIn { try await SupabaseAuthManager.signInWithKakao() } }
    }

    /// 공통 signin 후처리 — 서버에 사주 프로필이 이미 있으면 로컬 복원, 없으면 BirthInfoView 진입.
    /// 재로그인 시 로컬 SwiftData가 비어있어도 서버 데이터로 즉시 사용 가능하도록.
    private func performSignIn(_ signIn: @escaping () async throws -> UUID) async {
        isAuthenticating = true
        errorMessage = nil
        defer { isAuthenticating = false }
        do {
            _ = try await signIn()
            // 서버에 이미 saju_profile 있으면 (= 재로그인) → 로컬 복원 → RootView 자동 swap.
            if let snapshot = try await SupabaseAuthManager.fetchExistingProfile() {
                try OnboardingService.restoreLocalProfile(snapshot: snapshot, modelContext: modelContext)
            } else {
                // 신규 회원가입 흐름 → BirthInfoView 진입.
                showBirthInfo = true
            }
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = "로그인에 실패했어요. 다시 시도해 주세요.\n(\(error.localizedDescription))"
        }
    }
}

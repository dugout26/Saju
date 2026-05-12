import Foundation
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

@MainActor
final class KakaoAuthManager {

    static let shared = KakaoAuthManager()
    private init() {}

    func signIn() async throws -> KakaoAuthResult {
        try await withCheckedThrowingContinuation { cont in
            let handler: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    cont.resume(throwing: AuthError.kakaoError(error.localizedDescription))
                    return
                }
                guard let token else {
                    cont.resume(throwing: AuthError.invalidCredential)
                    return
                }
                Task { @MainActor in
                    do {
                        let result = try await self.fetchUserInfo(accessToken: token.accessToken)
                        cont.resume(returning: result)
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: handler)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: handler)
            }
        }
    }

    private func fetchUserInfo(accessToken: String) async throws -> KakaoAuthResult {
        try await withCheckedThrowingContinuation { cont in
            UserApi.shared.me { user, error in
                if let error {
                    cont.resume(throwing: AuthError.kakaoError(error.localizedDescription))
                    return
                }
                guard let user else {
                    cont.resume(throwing: AuthError.invalidCredential)
                    return
                }
                let result = KakaoAuthResult(
                    userId: String(user.id ?? 0),
                    nickname: user.kakaoAccount?.profile?.nickname ?? "",
                    email: user.kakaoAccount?.email ?? "",
                    accessToken: accessToken
                )
                cont.resume(returning: result)
            }
        }
    }

    func signOut() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            UserApi.shared.logout { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }
}

// MARK: - Models

struct KakaoAuthResult {
    let userId: String
    let nickname: String
    let email: String
    let accessToken: String
}

import AuthenticationServices
import Foundation

@MainActor
final class AppleAuthManager: NSObject {

    static let shared = AppleAuthManager()
    private override init() {}

    private var continuation: CheckedContinuation<AppleAuthResult, Error>?

    func signIn() async throws -> AppleAuthResult {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in continuation?.resume(throwing: AuthError.invalidCredential) }
            return
        }
        let result = AppleAuthResult(
            userId:    credential.user,
            fullName:  credential.fullName?.formatted() ?? "",
            email:     credential.email ?? "",
            idToken:   credential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        )
        Task { @MainActor in continuation?.resume(returning: result) }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in continuation?.resume(throwing: error) }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleAuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - Models

struct AppleAuthResult {
    let userId: String
    let fullName: String
    let email: String
    let idToken: String
}

enum AuthError: LocalizedError {
    case invalidCredential
    case kakaoError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:  return "인증 정보가 올바르지 않아요."
        case .kakaoError(let msg): return msg
        }
    }
}

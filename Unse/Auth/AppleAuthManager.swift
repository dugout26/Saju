import AuthenticationServices
import CryptoKit
import Foundation

@MainActor
final class AppleAuthManager: NSObject {

    static let shared = AppleAuthManager()
    private override init() {}

    private var continuation: CheckedContinuation<AppleAuthResult, Error>?
    private var currentRawNonce: String?

    func signIn() async throws -> AppleAuthResult {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
            let raw = Self.randomNonceString()
            currentRawNonce = raw
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(raw)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Nonce helpers (Supabase signInWithIdToken 필수)

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        for byte in bytes {
            result.append(charset[Int(byte) % charset.count])
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
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
            userId: credential.user,
            fullName: credential.fullName?.formatted() ?? "",
            email: credential.email ?? "",
            idToken: credential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? "",
            rawNonce: ""  // populated below on MainActor
        )
        Task { @MainActor in
            var resolved = result
            resolved.rawNonce = self.currentRawNonce ?? ""
            self.currentRawNonce = nil
            self.continuation?.resume(returning: resolved)
        }
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
    var rawNonce: String   // Supabase signInWithIdToken 검증용
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

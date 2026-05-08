import StoreKit
import Observation
import Foundation
@preconcurrency import Supabase

@Observable
@MainActor
final class SubscriptionManager {

    static let shared = SubscriptionManager()
    private init() {
        updateListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                await self.handleTransactionUpdate(result)
            }
        }
    }

    var products: [Product] = []
    var status: SubscriptionStatus = .free
    var isLoading = false

    private let productIds = ["unse.monthly", "unse.yearly"]
    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Load

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
            await refreshStatus()
        } catch {
            print("[SubscriptionManager] product load failed: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let txn = try checkVerified(verification)
            await txn.finish()
            await verifyOnServer(verification: verification)
            await refreshStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard (try? checkVerified(result)) != nil else { return }
        if case .verified(let txn) = result {
            await txn.finish()
        }
        await verifyOnServer(verification: result)
        await refreshStatus()
    }

    /// 서버 측 trust source. 클라이언트 단독 검증을 신뢰하지 않고 verify-receipt
    /// Edge Function이 JWS payload (bundleId, productId, expires) 재검증 + service_role로
    /// users.subscription_status 갱신. 클라이언트는 서버 응답으로 status 인식.
    private func verifyOnServer(verification: VerificationResult<Transaction>) async {
        let signedJWS = verification.jwsRepresentation

        guard let session = try? await SupabaseManager.shared.auth.session else { return }

        var request = URLRequest(url: Endpoint.verifyReceipt.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        struct Body: Encodable { let signed_transaction: String }
        request.httpBody = try? JSONEncoder().encode(Body(signed_transaction: signedJWS))

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[SubscriptionManager] verify-receipt failed: status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }
            // 서버가 users.subscription_status update 완료. refreshStatus가 다음 단계에서 entitlement 재확인.
        } catch {
            print("[SubscriptionManager] verify-receipt error: \(error)")
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshStatus()
    }

    // MARK: - Status

    func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            guard let txn = try? checkVerified(result),
                  productIds.contains(txn.productID) else { continue }
            if let exp = txn.expirationDate {
                status = exp > .now ? .premium : .free
            } else {
                status = .premium
            }
            return
        }
        status = .free
    }

    var isPremium: Bool { status == .premium || status == .trial }

    #if DEBUG
    /// 개발/테스트용 — 실제 결제 없이 PRO 토글
    func debugTogglePremium() {
        status = (status == .premium) ? .free : .premium
    }
    #endif

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):   return value
        case .unverified(_, let err): throw err
        }
    }

    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func trialDescription(for product: Product) -> String? {
        guard let price = product.subscription?.introductoryOffer?.displayPrice else { return nil }
        return "7일 무료 후 \(price)"
    }
}

import StoreKit
import Observation
import Foundation
@preconcurrency import Supabase
import FirebaseCrashlytics
import FirebaseAnalytics

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
    /// 서버 verify 실패 — UI에서 alert 표시 + retry 유도.
    var verifyError: String?

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
            // 서버 verify 성공 후에만 txn.finish — 서버 fail 시 다음 앱 실행에서 재시도 가능.
            let verified = await verifyOnServer(verification: verification)
            if verified, case .verified(let txn) = verification {
                await txn.finish()
                // GA4 스펙: 상품 데이터는 items 배열 안에. iOS SDK 16.20.0+에서
                // top-level item 파라미터는 BigQuery로 전달되지 않음.
                let item: [String: Any] = [
                    AnalyticsParameterItemID: product.id,
                    AnalyticsParameterPrice: NSDecimalNumber(decimal: product.price).doubleValue
                ]
                Analytics.logEvent(AnalyticsEventPurchase, parameters: [
                    AnalyticsParameterTransactionID: String(txn.id),
                    AnalyticsParameterCurrency: product.priceFormatStyle.currencyCode,
                    AnalyticsParameterValue: NSDecimalNumber(decimal: product.price).doubleValue,
                    AnalyticsParameterItems: [item]
                ])
            }
            await refreshStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard (try? checkVerified(result)) != nil else { return }
        let verified = await verifyOnServer(verification: result)
        if verified, case .verified(let txn) = result {
            await txn.finish()
        }
        await refreshStatus()
    }

    /// 서버 측 trust source. verify-receipt Edge Function이 App Store Server API로
    /// trusted transaction fetch → bundleId/productId/expires 검증 + service_role로
    /// users.subscription_status + subscriptions 갱신.
    /// - returns: 서버 검증 + DB 갱신 성공 여부. true면 호출자가 txn.finish 안전.
    @discardableResult
    private func verifyOnServer(verification: VerificationResult<Transaction>) async -> Bool {
        let signedJWS = verification.jwsRepresentation

        guard let session = try? await SupabaseManager.shared.auth.session else {
            verifyError = "구독 동기화 실패 — 로그인 세션을 확인할 수 없어요."
            return false
        }

        var request = URLRequest(url: Endpoint.verifyReceipt.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        struct Body: Encodable { let signed_transaction: String }
        request.httpBody = try? JSONEncoder().encode(Body(signed_transaction: signedJWS))

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                verifyError = "구독 동기화 실패 — 네트워크 응답이 올바르지 않아요."
                return false
            }
            guard http.statusCode == 200 else {
                let serverMsg = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error
                verifyError = serverMsg ?? "구독 동기화 실패 (status \(http.statusCode))."
                return false
            }
            // 서버 응답으로 local status 즉시 갱신 (refreshStatus는 entitlement도 다시 확인).
            if let resp = try? JSONDecoder().decode(VerifyResponse.self, from: data) {
                status = resp.is_premium ? .premium : .free
            }
            verifyError = nil
            return true
        } catch {
            Crashlytics.crashlytics().record(error: error)
            verifyError = "구독 동기화 실패 — 네트워크 오류. 잠시 후 다시 시도해주세요."
            return false
        }
    }

    private struct VerifyResponse: Decodable {
        let is_premium: Bool
        let subscription_status: String
        let expires_at: Int64?
    }
    private struct ErrorBody: Decodable { let error: String }

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

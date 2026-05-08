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
            await refreshStatus()
            await syncToSupabase(transaction: txn, product: product)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard let txn = try? checkVerified(result) else { return }
        await txn.finish()
        await refreshStatus()
        if let product = products.first(where: { $0.id == txn.productID }) {
            await syncToSupabase(transaction: txn, product: product)
        }
    }

    private func syncToSupabase(transaction: Transaction, product: Product) async {
        guard let userId = try? await SupabaseManager.shared.auth.session.user.id else { return }

        struct UserUpdate: Encodable {
            let subscription_status: String
            let subscription_expires_at: Date?
        }
        _ = try? await SupabaseManager.shared
            .from("users")
            .update(UserUpdate(
                subscription_status: status == .premium ? "premium" : "free",
                subscription_expires_at: transaction.expirationDate
            ))
            .eq("id", value: userId)
            .execute()

        struct Sub: Encodable {
            let user_id: UUID
            let plan: String
            let provider: String
            let provider_subscription_id: String
            let started_at: Date
            let current_period_end: Date
        }
        let plan = product.id.contains("monthly") ? "monthly" : "yearly"
        _ = try? await SupabaseManager.shared
            .from("subscriptions")
            .upsert(Sub(
                user_id: userId,
                plan: plan,
                provider: "apple_iap",
                provider_subscription_id: String(transaction.id),
                started_at: transaction.purchaseDate,
                current_period_end: transaction.expirationDate ?? transaction.purchaseDate
            ), onConflict: "provider,provider_subscription_id")
            .execute()
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

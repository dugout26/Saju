import StoreKit
import Observation

@Observable
@MainActor
final class SubscriptionManager {

    static let shared = SubscriptionManager()
    private init() {}

    var products: [Product] = []
    var status: SubscriptionStatus = .free
    var isLoading = false

    private let productIds = ["unse.monthly", "unse.yearly"]

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
        case .userCancelled, .pending:
            break
        @unknown default:
            break
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
        product.subscription?.introductoryOffer?.displayPrice
            .flatMap { "7일 무료 후 \($0)" }
    }
}

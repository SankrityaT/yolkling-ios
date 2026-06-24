import StoreKit
import SwiftUI

/// Yolkling+ — the monthly subscription that keeps the lights on. StoreKit 2:
/// loads the product, purchases, restores, and tracks entitlement live from the
/// transaction store (never trust a local flag). Free play is unaffected; this is
/// the supporter tier. Configure the product in App Store Connect; the bundled
/// Yolkling.storekit config lets it run in the simulator.
@MainActor @Observable
final class SubscriptionStore {
    static let monthlyID = "com.Sankritya.Yolkling.plus.monthly"

    private(set) var product: Product?
    private(set) var isPlus = false
    private(set) var purchasing = false

    nonisolated(unsafe) private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task { await loadProduct(); await refreshEntitlement() }
    }

    deinit { updatesTask?.cancel() }

    /// Price string for the paywall (falls back to a sensible default offline).
    var priceText: String { product?.displayPrice ?? "$4.99" }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.monthlyID]).first
    }

    /// Live entitlement check from the current transactions.
    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.monthlyID, t.revocationDate == nil {
                active = true
            }
        }
        isPlus = active
    }

    @discardableResult
    func subscribe() async -> Bool {
        guard let product else { return false }
        purchasing = true
        defer { purchasing = false }
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(let verification):
            if case .verified(let t) = verification {
                await t.finish()
                await refreshEntitlement()
                return isPlus
            }
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let t) = update {
                    await t.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }
}

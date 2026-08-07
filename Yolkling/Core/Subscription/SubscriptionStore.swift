import RevenueCat
import SwiftUI

/// Yolkling Plus — the supporter tier. Free play is never affected; this buys
/// expression, never wellbeing and never power (see docs/MONETIZATION.md).
///
/// Backed by RevenueCat rather than StoreKit directly, so what's on sale, at what price,
/// is configured in the dashboard instead of compiled in. Entitlement is always read
/// from `CustomerInfo` — never from a local flag.
///
/// **Singleton on purpose.** `Purchases.configure` may only be called once, and two
/// stores would drift out of sync on entitlement state. Construct nothing; use `.shared`.
///
/// Swift 6 note: this deliberately uses only RevenueCat's async APIs and
/// `customerInfoStream`. `PurchasesDelegate` and the completion-handler variants fight
/// `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor` and produce isolation diagnostics.
@MainActor @Observable
final class SubscriptionStore {

    /// The one instance. Safe to touch only after `Purchases.configure` has run, which
    /// `YolklingApp.init()` guarantees.
    static let shared = SubscriptionStore()

    private(set) var offering: Offering?
    private(set) var isPlus = false
    private(set) var purchasing = false

    /// Held for the app's lifetime — this is a singleton, so there's no deinit to
    /// cancel it from (and a `deinit` touching MainActor state is a Swift 6 error).
    private var listener: Task<Void, Never>?

    private init() {
        listener = listenForCustomerInfo()
        Task { await loadOfferings(); await refreshEntitlement() }
    }

    // MARK: What's for sale

    /// The package the paywall leads with. Falls back to whatever the offering has, so a
    /// dashboard change can't leave the paywall empty.
    var leadPackage: Package? {
        offering?.monthly ?? offering?.availablePackages.first
    }

    /// Localised price for the paywall, with an offline fallback.
    ///
    /// The fallback is marked in DEBUG so it can't be mistaken for a real fetched price
    /// — they'd otherwise render identically and hide a broken offering.
    var priceText: String {
        if let live = leadPackage?.storeProduct.localizedPriceString { return live }
        #if DEBUG
        return "$4.99 (fallback — offering not loaded)"
        #else
        return "$4.99"
        #endif
    }

    func loadOfferings() async {
        offering = try? await Purchases.shared.offerings().current
    }

    // MARK: Entitlement

    /// Live entitlement check. Never trust a cached local flag.
    func refreshEntitlement() async {
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        apply(info)
    }

    private func apply(_ info: CustomerInfo) {
        isPlus = info.entitlements[RevenueCatConfig.plusEntitlement]?.isActive == true
    }

    private func listenForCustomerInfo() -> Task<Void, Never> {
        Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
    }

    // MARK: Buying

    @discardableResult
    func subscribe() async -> Bool {
        guard let package = leadPackage else { return false }
        purchasing = true
        defer { purchasing = false }
        guard let result = try? await Purchases.shared.purchase(package: package) else { return false }
        guard !result.userCancelled else { return false }
        apply(result.customerInfo)
        return isPlus
    }

    func restore() async {
        guard let info = try? await Purchases.shared.restorePurchases() else { return }
        apply(info)
    }

    // MARK: The stipend (RevenueCat Virtual Currency)

    /// Lifetime Yolks granted by RevenueCat — i.e. every Yolk that came from money.
    private(set) var stipendGranted = 0

    /// Yolks granted since the last time we looked, to be credited into the spendable
    /// wallet. Returns 0 when nothing new has arrived.
    ///
    /// Why it works this way: RevenueCat's balance is append-only here, because we never
    /// deduct from it — spending happens in Supabase, and adjusting a RevenueCat balance
    /// needs a secret key that has no business being in a client. So the ledger only ever
    /// grows, and the delta since last check is exactly what's newly owed.
    ///
    /// That split is the design, not a workaround: RevenueCat records the Yolks that came
    /// from money, Supabase records the ones that came from living, and neither can be
    /// mistaken for the other.
    @discardableResult
    func claimStipend() async -> Int {
        Purchases.shared.invalidateVirtualCurrenciesCache()
        guard let currencies = try? await Purchases.shared.virtualCurrencies(),
              let balance = currencies[RevenueCatConfig.yolksCurrency]?.balance
        else { return 0 }

        stipendGranted = balance
        let key = Self.seenKey
        let seen = UserDefaults.standard.integer(forKey: key)
        guard balance > seen else { return 0 }

        UserDefaults.standard.set(balance, forKey: key)
        return balance - seen
    }

    private static let seenKey = "yolk.stipendSeen"

    // MARK: Identity

    /// Alias the anonymous RevenueCat user onto the signed-in Apple user id.
    ///
    /// Called when Sign in with Apple completes mid-session. We deliberately let
    /// RevenueCat mint its own anonymous id at launch rather than passing `InstallID`,
    /// because `logIn` then handles the "bought before signing in" transfer for us —
    /// a path that is easy to get wrong by hand.
    func identify(_ appUserID: String) async {
        guard let result = try? await Purchases.shared.logIn(appUserID) else { return }
        apply(result.customerInfo)
        await loadOfferings()
    }
}

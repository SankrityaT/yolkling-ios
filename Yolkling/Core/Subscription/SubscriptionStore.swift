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

    /// Whether the storefront has been reached yet.
    ///
    /// Needed because "no plans" and "not asked yet" look identical from `offering ==
    /// nil`, and the paywall has to tell a person which one they are looking at. A
    /// button reading "loading…" forever is what happens without this, and it is exactly
    /// what every user would see if the Paid Applications Agreement were unsigned.
    enum LoadState: Equatable { case loading, ready, unavailable }
    private(set) var loadState: LoadState = .loading
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

    var monthly: Package? { offering?.monthly }
    var annual: Package? { offering?.annual }

    /// A plan, as the paywall needs it.
    ///
    /// Deliberately a plain value rather than RevenueCat's `Package`. The convention in
    /// this project is that SDK types stay inside Core/Subscription, so the view layer
    /// cannot accidentally take a dependency the widget must never see. Everything the
    /// paywall renders is precomputed here from real store prices.
    struct Plan: Identifiable, Equatable {
        let id: String
        let title: String
        /// Localised, straight from StoreKit.
        let price: String
        /// "$2.92 / mo", annual only. nil otherwise.
        let perMonth: String?
        let isAnnual: Bool
        /// Percent saved against twelve months of the monthly. nil unless BOTH plans
        /// loaded, so a saving can never be printed that the store did not produce.
        let savingPercent: Int?
    }

    /// Every plan on offer, annual first so the cheaper-per-month option leads.
    var plans: [Plan] {
        let packages = [annual, monthly].compactMap { $0 }
        let source = packages.isEmpty ? (offering?.availablePackages ?? []) : packages
        return source.map { plan(from: $0) }
    }

    /// What the paywall selects on open: the annual when there is one.
    ///
    /// Not a dark pattern. It is the cheaper plan per month, and monthly stays one tap
    /// away and is never hidden.
    var defaultPlan: Plan? { plans.first { $0.isAnnual } ?? plans.first }

    private func plan(from package: Package) -> Plan {
        let isAnnual = package.packageType == .annual
        return Plan(
            id: package.identifier,
            title: isAnnual ? "yearly" : "monthly",
            price: package.storeProduct.localizedPriceString,
            perMonth: isAnnual ? monthlyEquivalent(of: package) : nil,
            isAnnual: isAnnual,
            savingPercent: isAnnual ? annualSavingPercent : nil
        )
    }

    /// The annual price divided by twelve, formatted in the store's own currency, so the
    /// two plans can be compared on one axis. Without it "$34.99" next to "$4.99" reads
    /// as the expensive one beside the cheap one, which is the opposite of the truth.
    private func monthlyEquivalent(of package: Package) -> String? {
        let product = package.storeProduct
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = product.priceFormatter?.locale ?? .current
        guard let text = f.string(from: (product.price / 12) as NSDecimalNumber) else { return nil }
        return "\(text) / mo"
    }

    private var annualSavingPercent: Int? {
        guard let a = annual?.storeProduct.price,
              let m = monthly?.storeProduct.price, m > 0 else { return nil }
        let yearOfMonthly = m * 12
        guard yearOfMonthly > a else { return nil }
        let saving = (yearOfMonthly - a) / yearOfMonthly * 100
        return Int(NSDecimalNumber(decimal: saving).doubleValue.rounded())
    }

    func loadOfferings() async {
        loadState = .loading
        offering = try? await Purchases.shared.offerings().current
        // Products can be absent for reasons that are nobody's fault and not
        // transient: the Paid Applications Agreement is unsigned, the products are
        // still in review, or the storefront does not carry them. Treat an empty
        // offering exactly like a failed fetch, because to the person looking at the
        // screen they are the same thing.
        loadState = plans.isEmpty ? .unavailable : .ready
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
    func subscribe(planID: String) async -> Bool {
        guard let package = (offering?.availablePackages.first { $0.identifier == planID }) else { return false }
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

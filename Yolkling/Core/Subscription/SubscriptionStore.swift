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

        /// "year" / "month", for "$34.99 per year" in the renewal disclosure. Derived
        /// from `title` so it can never disagree with the period shown on the plan card.
        var periodNoun: String {
            switch title {
            case "yearly":  "year"
            case "monthly": "month"
            case "weekly":  "week"
            case "daily":   "day"
            default:        title
            }
        }
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
        // Derived from the StoreKit product's own subscription period, NOT from
        // `packageType`. packageType comes from the package IDENTIFIER: anything that is
        // not exactly `$rc_annual` resolves to `.custom`, which read as `isAnnual =
        // false`. A yearly package with a custom id would therefore have rendered as
        // "yearly plan, $34.99 / month" -- a false price and period on a payment screen,
        // and a 3.1.2 rejection. The product's period is the fact; the identifier is a
        // naming convention.
        let period = package.storeProduct.subscriptionPeriod
        let isAnnual = period?.unit == .year
        return Plan(
            id: package.identifier,
            title: Self.periodTitle(period),
            price: package.storeProduct.localizedPriceString,
            perMonth: isAnnual ? monthlyEquivalent(of: package) : nil,
            isAnnual: isAnnual,
            savingPercent: isAnnual ? annualSavingPercent : nil
        )
    }

    /// "yearly" / "monthly" / "weekly", from the product's real period.
    nonisolated private static func periodTitle(_ period: SubscriptionPeriod?) -> String {
        guard let period else { return "subscription" }
        switch period.unit {
        case .year:  return period.value == 1 ? "yearly" : "every \(period.value) years"
        case .month: return period.value == 1 ? "monthly" : "every \(period.value) months"
        case .week:  return period.value == 1 ? "weekly" : "every \(period.value) weeks"
        case .day:   return period.value == 1 ? "daily" : "every \(period.value) days"
        @unknown default: return "subscription"
        }
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

    /// The outcome of a purchase attempt, in the three shapes the UI has to treat
    /// differently.
    ///
    /// This was a `Bool`, and the paywall did nothing at all when it came back false. Any
    /// failure, a declined card, a store outage, a parental restriction, produced a tap
    /// that visibly did nothing on a payment screen. Reported from device testing as
    /// "clicked buy and then nothing happened", which is precisely what the code did.
    ///
    /// Cancelling has to stay silent, because someone who backed out on purpose does not
    /// want to be told about it. Everything else has to say something.
    enum PurchaseOutcome: Equatable {
        case success
        /// They backed out. Not an error, and deliberately shows no message.
        case cancelled
        /// Something went wrong, with a line already written for a person to read.
        case failed(String)
    }

    func subscribe(planID: String) async -> PurchaseOutcome {
        guard let package = (offering?.availablePackages.first { $0.identifier == planID }) else {
            return .failed("that plan isn't available right now. try again in a moment.")
        }
        purchasing = true
        defer { purchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            apply(result.customerInfo)
            if isPlus { return .success }
            // Paid, but the entitlement has not landed yet. Never say the purchase
            // failed here: their money may well have moved.
            return .failed("the purchase went through, but supporter status hasn't arrived yet. give it a moment, then tap restore.")
        } catch {
            return .failed(Self.readable(error))
        }
    }

    /// Apple's and RevenueCat's errors, translated into something a person can act on.
    /// The raw `localizedDescription` is usually either empty or a sentence about
    /// StoreKit that means nothing to the person holding the phone.
    nonisolated private static func readable(_ error: Error) -> String {
        guard let code = (error as? RevenueCat.ErrorCode) else {
            return "the purchase didn't go through. nothing was charged."
        }
        switch code {
        case .productNotAvailableForPurchaseError:
            return "this plan isn't available on your store yet. it can take a few hours after setup."
        case .purchaseNotAllowedError:
            return "purchases are turned off on this device. check Screen Time restrictions in Settings."
        case .paymentPendingError:
            return "the purchase is waiting on approval. supporter status appears once it clears."
        case .storeProblemError, .networkError, .offlineConnectionError:
            return "couldn't reach the App Store. nothing was charged. try again in a moment."
        case .ineligibleError:
            return "this offer isn't available on your account."
        default:
            return "the purchase didn't go through. nothing was charged."
        }
    }

    /// What a restore attempt came to. `restore()` was Void with a `try?`, so the
    /// App-Store-mandated recovery path was a dead tap: no spinner, no "nothing to
    /// restore", no error — the same defect as the original purchase button, on the
    /// button a lapsed supporter reaches for when they are already unhappy.
    enum RestoreOutcome { case restored, nothingToRestore, failed }

    func restore() async -> RestoreOutcome {
        guard let info = try? await Purchases.shared.restorePurchases() else { return .failed }
        apply(info)
        return isPlus ? .restored : .nothingToRestore
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
    /// The lifetime Yolks RevenueCat has granted this customer, or nil if it could not
    /// be read. Append-only. The caller compares it against the per-account high-water
    /// mark it persists on the Player, credits the delta, and stores the two together.
    ///
    /// This deliberately no longer owns the "already seen" mark. It used to live in
    /// device-local UserDefaults, which reset on reinstall while the coins it guarded
    /// came back from the cloud backup, re-crediting the entire lifetime stipend. The
    /// mark now rides on the Player (see `Player.stipendSeen`) so it can never drift from
    /// the coins again.
    func lifetimeStipendBalance() async -> Int? {
        Purchases.shared.invalidateVirtualCurrenciesCache()
        guard let currencies = try? await Purchases.shared.virtualCurrencies(),
              let balance = currencies[RevenueCatConfig.yolksCurrency]?.balance
        else { return nil }
        stipendGranted = balance
        return balance
    }

    /// The legacy device-local mark, read ONCE to migrate existing installs so they do
    /// not re-credit on the upgrade that moves the mark onto the Player.

    /// Which RevenueCat customer the ledger currently belongs to.
    ///
    /// The stipend anchor is meaningless without this. `logIn` switches customers and
    /// `logOut` mints a brand new anonymous one, and each customer carries its own
    /// lifetime balance, so an anchor taken against one is not a statement about any
    /// other. Storing it alongside the mark is what lets the ledger notice the switch.
    var currentCustomerID: String { Purchases.shared.appUserID }

    /// Forget this device's RevenueCat identity. Called on account deletion so the next
    /// person to sign in on this phone is not treated as the deleted customer.
    func signOutOfPurchases() async {
        _ = try? await Purchases.shared.logOut()
    }

    // MARK: Identity

    /// Alias the anonymous RevenueCat user onto the signed-in Apple user id.
    ///
    /// Called when Sign in with Apple completes mid-session. We deliberately let
    /// RevenueCat mint its own anonymous id at launch rather than passing `InstallID`,
    /// because `logIn` then handles the "bought before signing in" transfer for us —
    /// a path that is easy to get wrong by hand.
    /// Returns whether RevenueCat is now definitely this customer.
    ///
    /// The Bool matters: reading the virtual-currency ledger while still on the anonymous
    /// user gives another customer's balance (or zero), and the stipend anchor treats
    /// whatever it reads as "already paid". Anchoring against the wrong identity is how
    /// a lifetime balance gets credited twice.
    @discardableResult
    func identify(_ appUserID: String) async -> Bool {
        guard let result = try? await Purchases.shared.logIn(appUserID) else { return false }
        apply(result.customerInfo)
        await loadOfferings()
        return true
    }
}

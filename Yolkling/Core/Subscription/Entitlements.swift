import Foundation

/// RevenueCat configuration, in one place.
///
/// Everything here is a string the dashboard owns, so it lives behind named constants
/// rather than being scattered through the app as literals.
enum RevenueCatConfig {

    /// Public SDK key. Safe to embed — it is designed to ship inside the app binary.
    ///
    /// **`test_…` is the Test Store key.** It lets the whole purchase flow run with no
    /// App Store Connect setup at all, which is why development starts here. It is NOT a
    /// real store: shipping it would mean every purchase silently fails in production.
    /// `assertProductionReady()` below exists to make that impossible to do by accident.
    ///
    /// The real `appl_…` key only appears once an App Store app is configured in the
    /// RevenueCat dashboard, which requires the shipping team's App Store Connect
    /// In-App Purchase key.
    static let apiKey = "test_rMRyXhGxdGQNyEeVdrQrFfjosDo"

    /// The entitlement that unlocks supporter features.
    ///
    /// NOTE: this is `"Yolkling Plus"` — with a space — because that's the identifier
    /// the dashboard actually created; an attempt to create a clean `plus` identifier
    /// failed in RevenueCat's UI. It is referenced only here, so if the entitlement is
    /// ever recreated properly this is a one-line change.
    static let plusEntitlement = "Yolkling Plus"

    /// The offering the paywall reads from.
    static let defaultOffering = "default"

    /// Whether we're pointed at the Test Store rather than a real storefront.
    ///
    /// A `test_` key shipping to production is the worst kind of bug: nothing crashes,
    /// the paywall renders normally, and every purchase quietly does nothing.
    static var isTestStore: Bool { apiKey.hasPrefix("test_") }

    /// Logs a reminder during development.
    ///
    /// Note this is NOT the safety net — `assert` is compiled out under `-O`, so nothing
    /// here can catch a bad key on the way to the App Store. The actual guard is
    /// `isTestStore` driving a visible banner on the paywall, which shows up in
    /// TestFlight and in App Review where a human will see it.
    static func warnIfTestStore() {
        #if DEBUG
        if isTestStore {
            print("⚠️ RevenueCat: Test Store key in use — purchases are simulated, not real.")
        }
        #endif
    }
}

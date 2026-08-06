import RevenueCat
import SwiftUI

@main
struct YolklingApp: App {
    init() {
        BrandFonts.register()
        // Fail fast on a malformed public URL at the very first launch step,
        // never mid-flow (App Review needs these to match App Store Connect).
        YolklingURLs.assertWellFormed()

        // Exactly once, before anything can touch SubscriptionStore.shared.
        // No appUserID: let RevenueCat mint an anonymous id, and alias it via
        // `SubscriptionStore.identify(_:)` when Sign in with Apple completes. That path
        // handles "bought before signing in" correctly, which hand-rolled ids don't.
        RevenueCatConfig.warnIfTestStore()
        #if DEBUG
        Purchases.logLevel = .debug   // offering fetches + entitlement resolution in the console
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Player.self)
    }
}

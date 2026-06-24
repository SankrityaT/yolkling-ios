import SwiftUI

@main
struct YolklingApp: App {
    init() {
        BrandFonts.register()
        // Fail fast on a malformed public URL at the very first launch step,
        // never mid-flow (App Review needs these to match App Store Connect).
        YolklingURLs.assertWellFormed()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Player.self)
    }
}

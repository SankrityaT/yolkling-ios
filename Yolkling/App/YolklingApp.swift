import SwiftUI

@main
struct YolklingApp: App {
    @State private var deepLink = DeepLinkRouter()

    init() {
        BrandFonts.register()
        // Fail fast on a malformed public URL at the very first launch step,
        // never mid-flow (App Review needs these to match App Store Connect).
        YolklingURLs.assertWellFormed()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(deepLink)
                .onOpenURL { url in
                    if let code = DeepLink.friendCode(from: url) {
                        deepLink.pendingFriendCode = code
                    }
                }
        }
        .modelContainer(for: Player.self)
    }
}

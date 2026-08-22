import Foundation
import SwiftUI

/// Parses an incoming Universal Link (`https://yolkling.com/add/<code>`) into a
/// friend code. Mirrors the same URL shape `QRScannerView` accepts when a code is
/// scanned, so a tapped link and a scanned QR behave identically.
enum DeepLink {
    static func friendCode(from url: URL) -> String? {
        guard let host = url.host, host.contains("yolkling.com"),
              url.pathComponents.count >= 3, url.pathComponents[1] == "add"
        else { return nil }
        let code = url.pathComponents[2]
        return code.hasPrefix("YOLK-") ? code : nil
    }
}

/// Carries a friend code from an incoming Universal Link (`.onOpenURL`, set at the
/// App root) down to wherever the Friends sheet is presented. Consumed once, then
/// cleared, so it can't re-fire the add-friend flow after the fact.
@MainActor @Observable
final class DeepLinkRouter {
    var pendingFriendCode: String?
}

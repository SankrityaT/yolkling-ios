import Foundation

/// A way into the app from outside it: a shared invite link, a scanned QR code.
///
/// This is the **conversion step of the growth loop**. `GrowFriendsView` has been
/// generating `https://yolkling.com/add/<code>` since day one with nothing on the
/// receiving end — no `onOpenURL`, no associated-domains entitlement — so every invite
/// anyone ever tapped opened the marketing site and stopped there. A loop with no
/// landing point isn't a loop.
enum DeepLink: Equatable, Sendable {
    case addFriend(code: String)

    /// Parse a URL, or a raw scanned code.
    ///
    /// Raw `YOLK-XXXX` is accepted so QR scanning and link handling share one
    /// definition of a valid code, rather than drifting apart in two places.
    static func parse(_ raw: String) -> DeepLink? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if isCode(trimmed) { return .addFriend(code: trimmed.uppercased()) }
        guard let url = URL(string: trimmed) else { return nil }
        return parse(url)
    }

    static func parse(_ url: URL) -> DeepLink? {
        guard let host = url.host(), host.contains("yolkling.com") else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2, parts[0].lowercased() == "add" else { return nil }
        let code = parts[1].uppercased()
        return isCode(code) ? .addFriend(code: code) : nil
    }

    /// Referral codes look like `YOLK-XXXX`.
    static func isCode(_ s: String) -> Bool {
        let u = s.uppercased()
        return u.hasPrefix("YOLK-") && u.count > "YOLK-".count
    }
}

import Foundation
import Observation

/// Holds a deep link until something is in a position to act on it.
///
/// The awkward case this exists for: a link can arrive **before there is a player**.
/// Someone taps a friend's invite, the App Store installs Yolkling, the app cold-starts
/// straight into onboarding — and at that moment there's no `Player`, no
/// `backendUserID`, and nothing that can redeem a code. Handling the link immediately
/// would silently drop it, which is exactly the person we most want to keep.
///
/// So a pending link is also written to `UserDefaults`: it survives the cold start,
/// waits through onboarding, and is replayed once a player exists.
@MainActor @Observable
final class Router {
    private static let pendingKey = "yolk.pendingDeepLink"

    /// The link waiting to be handled, if any.
    private(set) var pending: DeepLink?

    init() {
        pending = Self.readBuffered()
    }

    /// Handle an incoming universal link.
    func open(_ url: URL) {
        guard let link = DeepLink.parse(url) else { return }
        pending = link
        buffer(link)
    }

    /// Mark the pending link as dealt with. Must be called once acted on, or it
    /// replays on every launch forever.
    func consume() {
        pending = nil
        UserDefaults.standard.removeObject(forKey: Self.pendingKey)
    }

    private func buffer(_ link: DeepLink) {
        switch link {
        case .addFriend(let code):
            UserDefaults.standard.set(code, forKey: Self.pendingKey)
        }
    }

    private static func readBuffered() -> DeepLink? {
        guard let code = UserDefaults.standard.string(forKey: pendingKey),
              DeepLink.isCode(code) else { return nil }
        return .addFriend(code: code)
    }
}

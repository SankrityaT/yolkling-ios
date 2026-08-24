import Foundation

/// Decides WHEN to ask for an App Store review. Does not ask: that is
/// `@Environment(\.requestReview)`, which only a View can hold. Split that way so the
/// policy is pure and testable and the ask stays a one-liner at the call site.
///
/// **Why this exists at all.** The app shipped with no review prompt of any kind. Rating
/// count and average are a direct App Store ranking input, and a listing with zero
/// ratings converts badly no matter how good the keywords are, so all the ASO work in
/// AppStore/SUBMIT depends on this existing. It was the single largest growth gap.
///
/// **The policy is deliberately stingy.** Apple allows three prompts per 365 days and may
/// silently show none of them, so each one has to land on somebody who actually likes the
/// app. Asking a stranger on day one spends a scarce prompt to buy a one-star review.
///
/// Rules:
/// - Only at a care-streak milestone, which is already a celebrated moment.
/// - Only from `askAtStreak` (7 days) upward. Three days is too soon to have an opinion.
/// - Once per install, ever. Apple rate-limits anyway; asking twice only annoys.
/// - Never wired to a button. Apple's guidelines say not to solicit the prompt directly.
@MainActor
enum AppReview {

    /// First milestone worth asking on. `Rewards.streakBonus` fires at 3, 7, 14, 30, 60
    /// and 100; 3 is too early, 7 means a full week of showing up.
    static let askAtStreak = 7

    /// Whether this streak milestone is the right moment. RECORDS the ask when it says
    /// yes, so a caller cannot double-fire it.
    ///
    /// Takes the flag store as a parameter so tests never touch real `UserDefaults` and
    /// cannot leak state into each other.
    static func shouldAsk(atStreak streak: Int, store: ReviewFlagStore = .standard) -> Bool {
        guard streak >= askAtStreak else { return false }
        guard !store.hasAsked else { return false }
        store.hasAsked = true
        return true
    }
}

/// Indirection over the single bit of persistence `AppReview` needs, so the policy can be
/// tested without a real defaults database.
@MainActor
final class ReviewFlagStore {
    static let standard = ReviewFlagStore(defaults: .standard)

    private let defaults: UserDefaults
    private let key = "yolk.reviewAsked"

    init(defaults: UserDefaults) { self.defaults = defaults }

    var hasAsked: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

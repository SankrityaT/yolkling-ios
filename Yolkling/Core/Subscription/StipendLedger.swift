import Foundation

/// The stipend credit rule, in one testable place.
///
/// Extracted from `HomeView` so it can be tested directly rather than re-implemented in
/// the test file. A hand-copied test passed through two shipped regressions because it
/// asserted its own arithmetic instead of the app's.
///
/// The ledger this reads (RevenueCat's virtual currency) is LIFETIME and append-only: it
/// survives account deletion and reinstalls, and is never debited, because spending is
/// recorded in Supabase. So "how much is owed" is always the delta since the last look,
/// and the only hard part is establishing the starting point.
enum StipendLedger {

    /// What a look at the ledger concluded.
    struct Reading: Equatable {
        /// Yolks to hand over right now.
        var owed: Int
        /// The new high-water mark. Always persist this.
        var seen: Int
        /// The customer the mark now belongs to. Always persist this.
        var anchor: String
    }

    /// Yolks owed right now, given the balance of a specific RevenueCat customer.
    ///
    /// Three cases, and the middle one is the whole reason this takes a customer id:
    ///
    /// 1. **Same customer as last time.** Ordinary case. The balance only ever goes up,
    ///    and everything above the mark was earned since the last look, so pay it.
    ///
    /// 2. **A different customer.** The balance did not go up, it was *replaced*. Each
    ///    RevenueCat customer carries its own lifetime total, so a jump from one to
    ///    another is not earnings and must never be paid. Re-anchor silently. This is
    ///    reachable without trying: deleting the account calls logOut, which mints a
    ///    fresh anonymous customer with a balance of 0, and signing in afterwards
    ///    switches to one whose lifetime balance is whatever it always was. Read as a
    ///    delta, that pays out the entire lifetime balance again, once per reinstall.
    ///
    /// 3. **Never anchored.** A creature's first look. Anything already in the ledger was
    ///    earned by a previous life on this Apple ID and has already been handed out, so
    ///    record it without paying it.
    ///
    /// `wasAnchored` distinguishes case 3 from installs that anchored before the anchor
    /// carried an id. Those have a mark that is known good, so they adopt the current
    /// customer and keep crediting normally rather than re-anchoring, which would swallow
    /// anything they had earned since their last launch.
    ///
    /// The caller must only invoke this once RevenueCat is resolved to the intended
    /// customer, or the anchor latches onto a stranger's balance.
    static func credit(
        balance: Int,
        customer: String,
        seen: Int,
        anchor: String?,
        wasAnchored: Bool
    ) -> Reading {
        // Case 3, and the legacy half of it. An unanchored creature records the balance
        // without paying it; a legacy-anchored one keeps its mark and adopts the customer.
        guard anchor != nil || wasAnchored else {
            return Reading(owed: 0, seen: max(seen, balance), anchor: customer)
        }
        // Case 2. A switch, not an earning. Re-anchor at the new customer's own total.
        // Plain assignment, not max(): the new customer's balance is the only truth about
        // the new customer, and keeping a higher mark from the old one would swallow
        // everything the new one goes on to earn up to that figure.
        if let anchor, anchor != customer {
            return Reading(owed: 0, seen: balance, anchor: customer)
        }
        // Case 1.
        let owed = max(0, balance - seen)
        return Reading(owed: owed, seen: owed > 0 ? balance : seen, anchor: customer)
    }
}

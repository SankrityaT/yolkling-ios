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

    /// Yolks owed right now, updating the high-water mark in place.
    ///
    /// `anchored` is what stops a lifetime balance being paid twice. Until a creature has
    /// looked once, anything already in the ledger was earned by a PREVIOUS life on the
    /// same Apple ID and has already been handed out; anchoring records that without
    /// paying it again. A creature restored from a backup arrives already anchored.
    ///
    /// The caller must only invoke this once RevenueCat is resolved to the correct
    /// customer, or the anchor latches onto a stranger's balance.
    static func credit(balance: Int, seen: inout Int, anchored: inout Bool) -> Int {
        if !anchored {
            seen = max(seen, balance)
            anchored = true
        }
        let owed = max(0, balance - seen)
        if owed > 0 { seen = balance }
        return owed
    }
}

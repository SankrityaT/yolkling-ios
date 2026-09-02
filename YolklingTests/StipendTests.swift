import Testing
import Foundation
@testable import Yolkling

/// The stipend credit rule, tested against the REAL implementation rather than a copy of
/// it. Source of truth: `StipendLedger.credit`, called by `HomeView`'s `.task`.
///
/// The previous version of this suite re-implemented the arithmetic inline, so it passed
/// happily through two regressions that shipped: an anchor latching onto the anonymous
/// RevenueCat customer, and a gate that skipped the anchor for trial players. A test that
/// cannot fail when the app breaks is worse than no test, because it reads as coverage.
@Suite("Stipend")
struct StipendTests {

    @Test("a brand-new creature anchors and is paid nothing for a previous life's balance")
    func anchorsOnFirstLook() {
        var seen = 0; var anchored = false
        // A deleted account on this Apple ID already earned 600 lifetime.
        let owed = StipendLedger.credit(balance: 600, seen: &seen, anchored: &anchored)
        #expect(owed == 0, "re-onboarding re-credited a previous life's stipend")
        #expect(seen == 600)
        #expect(anchored)
    }

    @Test("a first-time subscriber is paid their first grant in full")
    func firstGrantPaid() {
        var seen = 0; var anchored = false
        _ = StipendLedger.credit(balance: 0, seen: &seen, anchored: &anchored)   // anchors at 0
        #expect(StipendLedger.credit(balance: 400, seen: &seen, anchored: &anchored) == 400)
    }

    @Test("each grant pays exactly once")
    func paysOncePerGrant() {
        var seen = 0; var anchored = false
        _ = StipendLedger.credit(balance: 0, seen: &seen, anchored: &anchored)
        #expect(StipendLedger.credit(balance: 400, seen: &seen, anchored: &anchored) == 400)
        #expect(StipendLedger.credit(balance: 400, seen: &seen, anchored: &anchored) == 0,
                "one grant was paid twice")
        #expect(StipendLedger.credit(balance: 800, seen: &seen, anchored: &anchored) == 400)
    }

    @Test("a creature restored from a backup keeps crediting and is never re-anchored")
    func restoredKeepsCrediting() {
        var seen = 400; var anchored = true      // arrived from the cloud snapshot
        #expect(StipendLedger.credit(balance: 800, seen: &seen, anchored: &anchored) == 400,
                "a restored creature lost a legitimate grant")
    }

    @Test("a trial subscriber who later signs in keeps the grant they paid for")
    func trialSubscriberNotSwallowed() {
        // Trial player, no Apple ID: RevenueCat's anonymous customer is the right one, so
        // the ledger IS read and anchors at 0 before any purchase.
        var seen = 0; var anchored = false
        _ = StipendLedger.credit(balance: 0, seen: &seen, anchored: &anchored)
        // They subscribe. The anonymous customer is granted 400.
        #expect(StipendLedger.credit(balance: 400, seen: &seen, anchored: &anchored) == 400,
                "the trial subscriber's first grant was swallowed")
        // They sign in; logIn aliases the anonymous customer onto the Apple ID, balance
        // carries across unchanged. Nothing further is owed.
        #expect(StipendLedger.credit(balance: 400, seen: &seen, anchored: &anchored) == 0)
    }

    @Test("the mark never moves backwards")
    func monotonic() {
        var seen = 800; var anchored = true
        // A stale or partial ledger read must not re-open the credit window.
        #expect(StipendLedger.credit(balance: 400, seen: &seen, anchored: &anchored) == 0)
        #expect(seen == 800, "the high-water mark moved backwards")
    }
}

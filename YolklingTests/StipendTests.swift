import Testing
@testable import Yolkling

/// Tests for the stipend credit rule.
///
/// These call `StipendLedger` directly. An earlier version re-implemented the arithmetic
/// in the test file and asserted against itself, which is how two regressions shipped
/// green. Every assertion here fails if the corresponding line in the ledger is broken.
struct StipendTests {

    private let alice = "rc_alice"
    private let bob = "rc_bob"

    // MARK: First look

    @Test func firstLookAnchorsWithoutPaying() {
        // An existing subscriber installing fresh. The lifetime balance was earned by a
        // previous life and has already been handed out; paying it again is the bug.
        let r = StipendLedger.credit(
            balance: 1200, customer: alice, seen: 0, anchor: nil, wasAnchored: false)
        #expect(r.owed == 0)
        #expect(r.seen == 1200)
        #expect(r.anchor == alice)
    }

    @Test func earningsAfterTheAnchorArePaid() {
        let r = StipendLedger.credit(
            balance: 1600, customer: alice, seen: 1200, anchor: alice, wasAnchored: true)
        #expect(r.owed == 400)
        #expect(r.seen == 1600)
    }

    @Test func nothingOwedTwice() {
        let first = StipendLedger.credit(
            balance: 400, customer: alice, seen: 0, anchor: alice, wasAnchored: true)
        #expect(first.owed == 400)
        // Same balance on the next launch. The mark moved, so there is nothing left.
        let second = StipendLedger.credit(
            balance: 400, customer: alice, seen: first.seen, anchor: first.anchor, wasAnchored: true)
        #expect(second.owed == 0)
        #expect(second.seen == 400)
    }

    // MARK: The trial subscriber

    @Test func trialSubscriberIsNotSwallowed() {
        // Buys during the 24-hour look-around, with no Apple ID: RevenueCat's anonymous
        // customer is the right customer, and the 400 they paid for must land.
        let anchored = StipendLedger.credit(
            balance: 0, customer: alice, seen: 0, anchor: nil, wasAnchored: false)
        #expect(anchored.owed == 0)

        let purchased = StipendLedger.credit(
            balance: 400, customer: alice, seen: anchored.seen,
            anchor: anchored.anchor, wasAnchored: true)
        #expect(purchased.owed == 400)
    }

    // MARK: Customer switches — the delete/reinstall double credit

    @Test func switchingCustomerNeverPays() {
        // Delete account calls logOut, minting a fresh anonymous customer at 0. Signing
        // back in switches to one whose lifetime balance is 600. Read as a delta that is
        // 600 free Yolks, repeatable once per reinstall.
        let r = StipendLedger.credit(
            balance: 600, customer: bob, seen: 0, anchor: alice, wasAnchored: true)
        #expect(r.owed == 0)
        #expect(r.seen == 600)
        #expect(r.anchor == bob)
    }

    @Test func reAnchorAdoptsTheNewBalanceEvenWhenLower() {
        // Switching to a customer with LESS in the ledger must drop the mark, or the new
        // customer's first 600 Yolks are silently swallowed.
        let switched = StipendLedger.credit(
            balance: 0, customer: bob, seen: 600, anchor: alice, wasAnchored: true)
        #expect(switched.seen == 0)

        let earned = StipendLedger.credit(
            balance: 600, customer: bob, seen: switched.seen,
            anchor: switched.anchor, wasAnchored: true)
        #expect(earned.owed == 600)
    }

    // MARK: Upgrading an install that anchored before anchors had ids

    @Test func legacyAnchorKeepsItsMark() {
        // stipendAnchorID is nil but the mark is known good. Re-anchoring here would
        // swallow the 400 earned since the last launch.
        let r = StipendLedger.credit(
            balance: 1600, customer: alice, seen: 1200, anchor: nil, wasAnchored: true)
        #expect(r.owed == 400)
        #expect(r.seen == 1600)
        #expect(r.anchor == alice)
    }

    @Test func legacyAnchorAdoptsCustomerAndStopsBeingLegacy() {
        let first = StipendLedger.credit(
            balance: 1200, customer: alice, seen: 1200, anchor: nil, wasAnchored: true)
        #expect(first.anchor == alice)
        // Now a real switch is detectable, where before it was indistinguishable.
        let switched = StipendLedger.credit(
            balance: 5000, customer: bob, seen: first.seen, anchor: first.anchor, wasAnchored: true)
        #expect(switched.owed == 0)
    }
}

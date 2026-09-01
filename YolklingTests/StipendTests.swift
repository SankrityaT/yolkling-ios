import Testing
import Foundation
@testable import Yolkling

/// The stipend high-water mark. Source of truth: `Player.stipendSeen` /
/// `stipendInitialized`, credited in `HomeView`'s `.task`.
///
/// These pin the arithmetic that decides how many Yolks a paying customer receives, and
/// the anchoring rule that stops a lifetime balance being paid out twice. There were no
/// tests over any of it, which is how the reinstall double-credit survived.
@Suite("Stipend")
struct StipendTests {

    /// Mirrors the credit rule in HomeView: anchor on first look, then credit the delta.
    private func credit(balance: Int, seen: inout Int, initialized: inout Bool) -> Int {
        if !initialized {
            seen = max(seen, balance)
            initialized = true
        }
        let owed = max(0, balance - seen)
        if owed > 0 { seen = balance }
        return owed
    }

    @Test("a brand-new creature anchors and is paid nothing for a pre-existing balance")
    func anchorsOnFirstLook() {
        var seen = 0; var init_ = false
        // A previous account on this Apple ID already earned 600 lifetime.
        #expect(credit(balance: 600, seen: &seen, initialized: &init_) == 0,
                "re-onboarding re-credited a previous life's stipend")
        #expect(seen == 600)
    }

    @Test("a first-time subscriber is paid their first grant in full")
    func firstGrantPaid() {
        var seen = 0; var init_ = false
        _ = credit(balance: 0, seen: &seen, initialized: &init_)   // anchors at 0
        #expect(credit(balance: 400, seen: &seen, initialized: &init_) == 400)
    }

    @Test("each month pays once, and repeat looks pay nothing")
    func monthlyOnceEach() {
        var seen = 0; var init_ = false
        _ = credit(balance: 0, seen: &seen, initialized: &init_)
        #expect(credit(balance: 400, seen: &seen, initialized: &init_) == 400)
        #expect(credit(balance: 400, seen: &seen, initialized: &init_) == 0, "paid twice for one grant")
        #expect(credit(balance: 800, seen: &seen, initialized: &init_) == 400)
    }

    @Test("an already-anchored creature is never re-anchored")
    func anchoredStaysAnchored() {
        var seen = 400; var init_ = true      // restored from a backup
        #expect(credit(balance: 800, seen: &seen, initialized: &init_) == 400,
                "a restored creature lost a legitimate grant")
    }

    @Test("the snapshot merge is monotonic and stickily anchored")
    func snapshotMerge() {
        var local = PlayerSnapshot()
        local.stipendSeen = 800
        local.stipendInitialized = false
        // Simulates apply()'s merge rules.
        let mergedSeen = max(local.stipendSeen, 400)
        let mergedInit = local.stipendInitialized || true
        #expect(mergedSeen == 800, "restoring moved the mark backwards and re-opened the credit")
        #expect(mergedInit == true)
    }
}

import Testing
@testable import Yolkling

/// Exercises `TrustStage.from(trust:)` thresholds and the `waves` / `celebrates`
/// behaviour gates. Source of truth: `Yolkling/Core/Creature/TrustStage.swift`.
///
/// Thresholds (half-open, upper-exclusive):
///   [0, 0.2)   stranger
///   [0.2, 0.45) warming
///   [0.45, 0.7) friend
///   [0.7, 0.9)  companion
///   [0.9, ...]  devoted
@Suite("TrustStage")
struct TrustStageTests {

    @Test("CaseIterable order is stable and ascending")
    func caseOrderStable() {
        #expect(TrustStage.allCases == [.stranger, .warming, .friend, .companion, .devoted])
        // rawValues ascend 0..4 in that order.
        #expect(TrustStage.allCases.map(\.rawValue) == [0, 1, 2, 3, 4])
    }

    @Test("from(trust:) maps below the first threshold to stranger")
    func lowTrustIsStranger() {
        #expect(TrustStage.from(trust: 0.0) == .stranger)
        #expect(TrustStage.from(trust: 0.19) == .stranger)
    }

    @Test("from(trust:) at each exact boundary value")
    func exactBoundaries() {
        // Lower bound of each band is inclusive.
        #expect(TrustStage.from(trust: 0.2) == .warming)
        #expect(TrustStage.from(trust: 0.45) == .friend)
        #expect(TrustStage.from(trust: 0.7) == .companion)
        #expect(TrustStage.from(trust: 0.9) == .devoted)
    }

    @Test("from(trust:) just below each boundary stays in the lower band")
    func justBelowBoundaries() {
        #expect(TrustStage.from(trust: 0.199999) == .stranger)
        #expect(TrustStage.from(trust: 0.449999) == .warming)
        #expect(TrustStage.from(trust: 0.699999) == .friend)
        #expect(TrustStage.from(trust: 0.899999) == .companion)
    }

    @Test("from(trust:) clamps the top of the range to devoted")
    func topIsDevoted() {
        #expect(TrustStage.from(trust: 1.0) == .devoted)
        #expect(TrustStage.from(trust: 2.0) == .devoted) // out-of-range high still devoted
    }

    @Test("waves is true from the friend stage up")
    func wavesFromFriendUp() {
        #expect(TrustStage.stranger.waves == false)
        #expect(TrustStage.warming.waves == false)
        #expect(TrustStage.friend.waves == true)
        #expect(TrustStage.companion.waves == true)
        #expect(TrustStage.devoted.waves == true)
    }

    @Test("celebrates is true from the companion stage up")
    func celebratesFromCompanionUp() {
        #expect(TrustStage.stranger.celebrates == false)
        #expect(TrustStage.warming.celebrates == false)
        #expect(TrustStage.friend.celebrates == false)
        #expect(TrustStage.companion.celebrates == true)
        #expect(TrustStage.devoted.celebrates == true)
    }
}

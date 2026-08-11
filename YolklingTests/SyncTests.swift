import Testing
import Foundation
@testable import Yolkling

/// Exercises the cloud-backup boundary: `PlayerSnapshot` value semantics, its JSON
/// round-trip, and the merge rules `apply(to:)` enforces on restore.
/// Source of truth: `Yolkling/Core/Sync/SyncClient.swift`.
///
/// The merge rules are the part worth testing. A restore that silently took the LOWER
/// coin balance, or that dropped items bought on this device before signing in, would
/// look like the backup working right up until it cost someone their wallet.
///
/// `@MainActor` because `PlayerSnapshot.init(_:)` and `apply(to:)` both are.
@MainActor
@Suite("Sync")
struct SyncTests {

    /// Pinned to a whole second. `Player.createdAt` defaults to `.now`, so two calls
    /// would otherwise differ by microseconds and never compare equal — and the backup
    /// coders use ISO8601, which is second-resolution, so sub-second precision would not
    /// survive a round-trip either.
    private static let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func samplePlayer() -> Player {
        let p = Player(
            name: "Yolky",
            colorHex: 0xFFC23B,
            styleRaw: "classic",
            startingMoodRaw: "happy",
            coins: 240,
            ownedItemIDs: ["party-hat", "crown"],
            equippedItemIDs: ["crown"],
            createdAt: Self.fixedDate
        )
        p.careStreak = 6
        p.discoveredSpeciesIDs = ["sprout", "tuft"]
        p.trust = 0.42
        return p
    }

    private func sampleSnapshot() -> PlayerSnapshot { PlayerSnapshot(samplePlayer()) }

    // MARK: Equatable / value semantics

    @Test("PlayerSnapshot is Equatable: an identical copy compares equal")
    func snapshotEquatable() {
        #expect(sampleSnapshot() == sampleSnapshot())
    }

    @Test("PlayerSnapshot inequality: any changed field breaks equality")
    func snapshotInequality() {
        let base = sampleSnapshot()

        var mutated = base
        mutated.coins += 1
        #expect(base != mutated)

        var renamed = base
        renamed.name = "Different"
        #expect(base != renamed)

        var reowned = base
        reowned.ownedItemIDs.append("beanie")
        #expect(base != reowned)
    }

    // MARK: JSON round-trip

    /// The encoder and decoder must agree on dates. They are separate computed
    /// properties, so nothing but a test stops one of them drifting to a different
    /// strategy and turning every restore into a silent `nil`.
    @Test("PlayerSnapshot round-trips through the backup coders unchanged")
    func snapshotJSONRoundTrip() throws {
        let original = sampleSnapshot()
        let data = try JSONEncoder.backup.encode(original)
        let decoded = try JSONDecoder.backup.decode(PlayerSnapshot.self, from: data)
        #expect(decoded == original)
    }

    /// Every field is defaulted precisely so an older backup, written before a field
    /// existed, still decodes instead of failing whole.
    @Test("A backup missing newer keys still decodes")
    func snapshotDecodesPartialJSON() throws {
        let json = Data(#"{"name":"Old","coins":12}"#.utf8)
        let decoded = try JSONDecoder.backup.decode(PlayerSnapshot.self, from: json)
        #expect(decoded.name == "Old")
        #expect(decoded.coins == 12)
        #expect(decoded.roomThemeID == "room-cozy")   // default, not a decode failure
        #expect(decoded.restTokens == 2)
    }

    // MARK: Restore merge rules

    @Test("apply(to:) restores identity fields verbatim")
    func applyRestoresIdentity() {
        let snapshot = sampleSnapshot()
        let fresh = Player(name: "?", colorHex: 0, styleRaw: "classic", startingMoodRaw: "happy")
        snapshot.apply(to: fresh)

        #expect(fresh.name == "Yolky")
        #expect(fresh.colorHex == 0xFFC23B)
        #expect(fresh.careStreak == 6)
        #expect(fresh.discoveredSpeciesIDs.sorted() == ["sprout", "tuft"])
        #expect(fresh.trust == 0.42)
    }

    /// Coins take the HIGHER of the two, matching `push_wallet`'s merge. Restoring must
    /// never be a way to lose Yolks earned on this device before signing in.
    @Test("apply(to:) keeps the higher coin balance, whichever side it is on")
    func applyKeepsHigherCoins() {
        let snapshot = sampleSnapshot()          // 240

        let richer = Player(name: "a", colorHex: 0, styleRaw: "classic",
                            startingMoodRaw: "happy", coins: 900)
        snapshot.apply(to: richer)
        #expect(richer.coins == 900)

        let poorer = Player(name: "b", colorHex: 0, styleRaw: "classic",
                            startingMoodRaw: "happy", coins: 10)
        snapshot.apply(to: poorer)
        #expect(poorer.coins == 240)
    }

    /// Owned items UNION rather than replace, for the same reason.
    @Test("apply(to:) unions owned items instead of overwriting them")
    func applyUnionsOwned() {
        let snapshot = sampleSnapshot()          // party-hat, crown
        let local = Player(name: "c", colorHex: 0, styleRaw: "classic",
                           startingMoodRaw: "happy", ownedItemIDs: ["beanie"])
        snapshot.apply(to: local)
        #expect(Set(local.ownedItemIDs) == ["party-hat", "crown", "beanie"])
    }

    // MARK: isWorthRestoring

    /// A backup of a barely-started player is not worth interrupting anyone for.
    @Test("A fresh player's snapshot is not worth restoring")
    func freshSnapshotNotWorthRestoring() {
        let fresh = Player(name: "New", colorHex: 0, styleRaw: "classic",
                           startingMoodRaw: "happy", coins: Wallet.welcomeGrant)
        #expect(PlayerSnapshot(fresh).isWorthRestoring == false)
    }

    @Test("A lived-in snapshot is worth restoring")
    func livedInSnapshotWorthRestoring() {
        #expect(sampleSnapshot().isWorthRestoring)
    }

    /// Each of the three conditions should carry on its own, so none can rot unnoticed
    /// behind another.
    @Test("Any one of streak, discoveries, or surplus coins is enough on its own")
    func eachConditionCarriesAlone() {
        func base() -> Player {
            Player(name: "n", colorHex: 0, styleRaw: "classic",
                   startingMoodRaw: "happy", coins: Wallet.welcomeGrant)
        }

        let streaked = base(); streaked.careStreak = 1
        #expect(PlayerSnapshot(streaked).isWorthRestoring)

        let found = base(); found.discoveredSpeciesIDs = ["sprout"]
        #expect(PlayerSnapshot(found).isWorthRestoring)

        let earned = base(); earned.coins = Wallet.welcomeGrant + 1
        #expect(PlayerSnapshot(earned).isWorthRestoring)
    }
}

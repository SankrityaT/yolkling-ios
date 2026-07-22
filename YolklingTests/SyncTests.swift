import Testing
import Foundation
@testable import Yolkling

/// Exercises the sync boundary: `PlayerSnapshot` value semantics and the
/// `LocalOnlySyncClient` fallback contract. Source of truth:
/// `Yolkling/Core/Sync/SyncClient.swift`.
@Suite("Sync")
struct SyncTests {

    private func sampleSnapshot() -> PlayerSnapshot {
        PlayerSnapshot(
            appleUserID: "apple-123",
            name: "Yolky",
            colorHex: 0xFFC23B,
            styleRaw: "classic",
            coins: 240,
            ownedItemIDs: ["party-hat", "crown"],
            equippedItemIDs: ["crown"],
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    // MARK: Equatable / value semantics

    @Test("PlayerSnapshot is Equatable: an identical copy compares equal")
    func snapshotEquatable() {
        let a = sampleSnapshot()
        let b = sampleSnapshot()
        #expect(a == b)
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

    // TODO: PlayerSnapshot does NOT currently conform to `Codable` (it is declared
    // `Sendable, Equatable` only). A retroactive `extension PlayerSnapshot: Codable {}`
    // in this test module cannot use synthesized Codable (synthesis must be in the
    // type's own module/file), so a real JSONEncoder/JSONDecoder round-trip is not
    // testable from here yet. When the app adds `Codable` to PlayerSnapshot, enable:
    //
    // @Test("PlayerSnapshot round-trips through JSON equal")
    // func snapshotJSONRoundTrip() throws {
    //     let original = sampleSnapshot()
    //     let data = try JSONEncoder().encode(original)
    //     let decoded = try JSONDecoder().decode(PlayerSnapshot.self, from: data)
    //     #expect(decoded == original)
    // }

    // MARK: LocalOnlySyncClient contract

    @Test("LocalOnlySyncClient.push is a no-op (does not throw)")
    func pushIsNoOp() async throws {
        let client = LocalOnlySyncClient()
        try await client.push(sampleSnapshot())
        // No cloud state exists to observe; the contract is simply that it succeeds
        // silently and never throws.
    }

    @Test("LocalOnlySyncClient.pull always returns nil")
    func pullReturnsNil() async throws {
        let client = LocalOnlySyncClient()
        let result = try await client.pull(appleUserID: "apple-123")
        #expect(result == nil)
    }

    @Test("LocalOnlySyncClient.pull returns nil even after a push (no persistence)")
    func pullNilAfterPush() async throws {
        let client = LocalOnlySyncClient()
        try await client.push(sampleSnapshot())
        let result = try await client.pull(appleUserID: "apple-123")
        #expect(result == nil)
    }
}

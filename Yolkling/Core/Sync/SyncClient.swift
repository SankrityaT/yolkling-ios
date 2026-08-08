import Foundation
import SwiftData

/// The two-layer data architecture:
///
/// - **SwiftData (local-first):** the `Player` @Model is always the instant, offline
///   source of truth on-device. Everything works with no network and no account.
/// - **Supabase (cloud backup):** `PlayerBackup` pushes/pulls that state when the user
///   is signed in with Apple. This is what makes "it can't truly die" true.
///
/// Deliberately NOT duplicated here, because it already syncs elsewhere:
/// coins + owned items (`push_wallet`), the room (`publish_room`), founding species
/// (`my_founding`). What this stores is the creature ITSELF — who it is, and everything
/// it has lived through.

/// A point-in-time snapshot of everything that makes a creature yours.
///
/// Codable rather than hand-mapped so a new `Player` field is one line here instead of
/// three, and an older backup missing a newer key still decodes (every field has a
/// default). Losing a field on restore is recoverable; failing to decode the whole
/// backup is not.
struct PlayerSnapshot: Codable, Sendable, Equatable {
    var name: String = ""
    var colorHex: Int = 0xFFC23B
    var styleRaw: String = "classic"
    var startingMoodRaw: String = "happy"
    var accentHex: Int?
    var patternRaw: String = "none"

    var foundingOwnedIDs: [String] = []
    var activeFoundingID: String?
    var discoveredSpeciesIDs: [String] = []

    var careStreak: Int = 0
    var lastCareDate: Date?
    var restTokens: Int = 2

    var weekStart: Date?
    var weekCareDays: Int = 0
    var weeklyClaimed: Bool = false

    var roomThemeID: String = "room-cozy"
    var placedDecorByZone: [String: String]?

    var coins: Int = 0
    var ownedItemIDs: [String] = []
    var equippedItemIDs: [String] = []

    var trust: Double = 0
    var createdAt: Date = .now

    init() {}

    @MainActor
    init(_ p: Player) {
        name = p.name
        colorHex = p.colorHex
        styleRaw = p.styleRaw
        startingMoodRaw = p.startingMoodRaw
        accentHex = p.accentHex
        patternRaw = p.patternRaw
        foundingOwnedIDs = p.foundingOwnedIDs
        activeFoundingID = p.activeFoundingID
        discoveredSpeciesIDs = p.discoveredSpeciesIDs
        careStreak = p.careStreak
        lastCareDate = p.lastCareDate
        restTokens = p.restTokens
        weekStart = p.weekStart
        weekCareDays = p.weekCareDays
        weeklyClaimed = p.weeklyClaimed
        roomThemeID = p.roomThemeID
        placedDecorByZone = p.placedDecorByZone
        coins = p.coins
        ownedItemIDs = p.ownedItemIDs
        equippedItemIDs = p.equippedItemIDs
        trust = p.trust
        createdAt = p.createdAt
    }

    /// Write this snapshot over a live `Player`.
    @MainActor
    func apply(to p: Player) {
        p.name = name
        p.colorHex = colorHex
        p.styleRaw = styleRaw
        p.startingMoodRaw = startingMoodRaw
        p.accentHex = accentHex
        p.patternRaw = patternRaw
        p.foundingOwnedIDs = foundingOwnedIDs
        p.activeFoundingID = activeFoundingID
        p.discoveredSpeciesIDs = discoveredSpeciesIDs
        p.careStreak = careStreak
        p.lastCareDate = lastCareDate
        p.restTokens = restTokens
        p.weekStart = weekStart
        p.weekCareDays = weekCareDays
        p.weeklyClaimed = weeklyClaimed
        p.roomThemeID = roomThemeID
        p.placedDecorByZone = placedDecorByZone
        // Coins take the HIGHER of the two, matching push_wallet's merge — a restore must
        // never be a way to lose Yolks you earned on this device before signing in.
        p.coins = max(p.coins, coins)
        p.ownedItemIDs = Array(Set(p.ownedItemIDs).union(ownedItemIDs))
        p.equippedItemIDs = equippedItemIDs
        p.trust = trust
    }

    /// Whether this looks like a creature worth restoring over what's here.
    /// A backup of a barely-started player isn't worth interrupting anyone for.
    var isWorthRestoring: Bool {
        careStreak > 0 || !discoveredSpeciesIDs.isEmpty || coins > Wallet.welcomeGrant
    }
}

/// Cloud backup, keyed on the Sign in with Apple id.
///
/// An anonymous `InstallID` is deliberately not good enough: it lives in UserDefaults and
/// dies with the app, so backing up to it would be a promise that fails precisely when
/// it's needed.
@MainActor
enum PlayerBackup {
    private static let client = SupabaseClient.shared
    private static let lastPushKey = "yolk.lastBackupPush"

    /// Save, at most once every few minutes. The app persists on nearly every
    /// interaction, and backing up on each one would be a request per tap for state that
    /// changes meaningfully a few times a day.
    static func push(_ player: Player, appleUserID: String?, force: Bool = false) async {
        guard let appleUserID, !appleUserID.isEmpty else { return }
        if !force, let last = UserDefaults.standard.object(forKey: lastPushKey) as? Date,
           Date().timeIntervalSince(last) < 300 { return }

        let snapshot = PlayerSnapshot(player)
        guard let data = try? JSONEncoder.backup.encode(snapshot),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        if await client.pushPlayerState(userID: appleUserID, state: obj) {
            UserDefaults.standard.set(Date(), forKey: lastPushKey)
        }
    }

    /// Look for a backup. Returns nil when there is nothing saved — which is NOT the same
    /// as an empty creature, and the caller must not treat it as one.
    static func pull(appleUserID: String) async -> PlayerSnapshot? {
        guard let obj = await client.pullPlayerState(userID: appleUserID),
              let data = try? JSONSerialization.data(withJSONObject: obj)
        else { return nil }
        return try? JSONDecoder.backup.decode(PlayerSnapshot.self, from: data)
    }
}

extension JSONEncoder {
    /// ISO8601 dates so a backup stays readable in the dashboard and survives a decoder
    /// strategy change on either side.
    static var backup: JSONEncoder {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }
}

extension JSONDecoder {
    static var backup: JSONDecoder {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }
}

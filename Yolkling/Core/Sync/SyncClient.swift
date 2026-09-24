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
    var walletVersion: Int = 0
    var stipendSeen: Int = 0
    var stipendInitialized: Bool = false
    var stipendAnchorID: String? = nil
    var ownedItemIDs: [String] = []
    var equippedItemIDs: [String] = []

    var trust: Double = 0
    var createdAt: Date = .now

    init() {}

    /// Decode field by field, falling back to each property's default.
    ///
    /// This CANNOT be left to synthesis. Swift's synthesized decoder does not consult
    /// property initializers — a missing key on a non-optional throws `keyNotFound`
    /// regardless of the default written above it. So the resilience this type's comment
    /// promises did not exist: the moment a field was added here, every backup written by
    /// an older build stopped decoding *in full*, and `PlayerBackup.pull`'s `try?` turned
    /// that into a silent nil. The caller reads nil as "no backup saved" and moves on, so
    /// the failure mode was a creature that quietly did not come back.
    ///
    /// Forward compatibility matters just as much: an OLDER app decoding a NEWER backup
    /// ignores keys it doesn't know rather than failing, which is what lets someone with
    /// two devices on different versions keep both.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // The defaults live on the properties; this is how we read them without
        // touching `self` before it is initialised.
        let d = PlayerSnapshot()
        func get<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            ((try? c.decodeIfPresent(T.self, forKey: key)) ?? nil) ?? fallback
        }
        name              = get(.name, d.name)
        colorHex          = get(.colorHex, d.colorHex)
        styleRaw          = get(.styleRaw, d.styleRaw)
        startingMoodRaw   = get(.startingMoodRaw, d.startingMoodRaw)
        accentHex         = try? c.decodeIfPresent(Int.self, forKey: .accentHex)
        patternRaw        = get(.patternRaw, d.patternRaw)
        foundingOwnedIDs  = get(.foundingOwnedIDs, d.foundingOwnedIDs)
        activeFoundingID  = try? c.decodeIfPresent(String.self, forKey: .activeFoundingID)
        discoveredSpeciesIDs = get(.discoveredSpeciesIDs, d.discoveredSpeciesIDs)
        careStreak        = get(.careStreak, d.careStreak)
        lastCareDate      = try? c.decodeIfPresent(Date.self, forKey: .lastCareDate)
        restTokens        = get(.restTokens, d.restTokens)
        weekStart         = try? c.decodeIfPresent(Date.self, forKey: .weekStart)
        weekCareDays      = get(.weekCareDays, d.weekCareDays)
        weeklyClaimed     = get(.weeklyClaimed, d.weeklyClaimed)
        roomThemeID       = get(.roomThemeID, d.roomThemeID)
        placedDecorByZone = try? c.decodeIfPresent([String: String].self, forKey: .placedDecorByZone)
        coins             = get(.coins, d.coins)
        walletVersion     = get(.walletVersion, d.walletVersion)
        stipendSeen       = get(.stipendSeen, d.stipendSeen)
        stipendInitialized = get(.stipendInitialized, d.stipendInitialized)
        stipendAnchorID   = try? c.decodeIfPresent(String.self, forKey: .stipendAnchorID)
        ownedItemIDs      = get(.ownedItemIDs, d.ownedItemIDs)
        equippedItemIDs   = get(.equippedItemIDs, d.equippedItemIDs)
        trust             = get(.trust, d.trust)
        createdAt         = get(.createdAt, d.createdAt)
    }

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
        walletVersion = p.walletVersion
        stipendSeen = p.stipendSeen
        stipendInitialized = p.stipendInitialized
        stipendAnchorID = p.stipendAnchorID
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
        // A RESTORE is the one place the old max() is still right: this device may have
        // earned Yolks before signing in, and the backup may hold a balance it has never
        // seen. Take the better of the two, then claim a version above both so the merged
        // number is the one that wins from here on.
        p.coins = max(p.coins, coins)
        p.walletVersion = max(p.walletVersion, walletVersion) + 1
        // Monotonic like coins: you have seen at least as much stipend as the higher of
        // the two ledgers. Restoring can never move the mark backwards and re-open the
        // double-credit window.
        p.stipendSeen = max(p.stipendSeen, stipendSeen)
        // Sticky: once either side has anchored, the restored creature is anchored.
        p.stipendInitialized = p.stipendInitialized || stipendInitialized
        // Only adopt a restored anchor when there is no local one. A local anchor
        // describes the customer this device is actually signed in as; a snapshot's
        // may name a customer we are no longer using, which would look like a switch.
        p.stipendAnchorID = p.stipendAnchorID ?? stipendAnchorID
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

    /// When a backup last actually reached the server, or nil if one never has.
    ///
    /// Only set after `pushPlayerState` returns success, so it means "this creature
    /// exists on the server", not "we tried". Profile shows it, because the difference
    /// between those two is the whole point of that screen.
    static var lastPushedAt: Date? {
        UserDefaults.standard.object(forKey: lastPushKey) as? Date
    }

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

// Cloud backup SHIPPED on this branch — the comment that stood here described it as
// future work. See PlayerBackup above and docs/sql/backup.sql.
extension JSONDecoder {
    static var backup: JSONDecoder {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }
}
/*
// SupabaseSyncClient (the cloud implementation) is built once we have the
// yolkling Supabase project access + the Sign in with Apple identity. It maps
// PlayerSnapshot to the `app_users` / `inventory` rows (see docs/sql/rewards.sql)
// over the Supabase client, keyed by appleUserID. Reconciliation: last-write-wins
// by updatedAt, with the server authoritative for friendship state. Privacy: raw
// wellness signals stay on-device; only creature/economy state syncs. (A future
// Core/Crypto layer could E2E-encrypt synced content; not claimed until it ships.)
*/

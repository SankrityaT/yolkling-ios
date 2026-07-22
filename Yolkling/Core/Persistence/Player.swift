import SwiftData
import Foundation

/// A stable id for this install, kept in UserDefaults so it survives launches
/// (lost only on uninstall). Used for the backend until Sign in with Apple.
enum InstallID {
    private nonisolated static let key = "yolk.installID"
    nonisolated static var current: String {
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}

/// The persisted player: their creature's identity + economy. Stored locally
/// with SwiftData (instant + offline); later this syncs to Supabase keyed by the
/// Sign in with Apple id. Only primitives live here, so Core has no dependency on
/// the feature layer; views reconstruct `Vibe`/`Mood` from these fields.
@Model
final class Player {
    var name: String
    var colorHex: Int
    var styleRaw: String
    var startingMoodRaw: String

    /// Species identity beyond colour + top feature: an optional accent colour and
    /// a body pattern. Defaulted so existing saves migrate cleanly.
    var accentHex: Int?
    var patternRaw: String = "none"

    /// Limited-edition founding species the player owns (grant-only), and the one
    /// they are currently wearing (its `Species.id`, or nil for their own look).
    var foundingOwnedIDs: [String] = []
    var activeFoundingID: String?

    /// Species the player has discovered for the collection (the Dex). New players
    /// start with a small head start (endowed progress, see SpeciesSets.headStart).
    var discoveredSpeciesIDs: [String] = []

    /// The kind care streak: current length, last care day, and free rest tokens
    /// that absorb a missed day so the streak pauses instead of shattering.
    var careStreak: Int = 0
    var lastCareDate: Date?
    var restTokens: Int = 2

    /// Weekly challenge progress (care N days in a calendar week for a bonus).
    var weekStart: Date?
    var weekCareDays: Int = 0
    var weeklyClaimed: Bool = false

    /// The room theme the player has applied (owned themes live in the wallet).
    var roomThemeID: String = "room-cozy"

    // economy
    var coins: Int
    var ownedItemIDs: [String]
    var equippedItemIDs: [String]

    /// The Sign in with Apple stable user id, once they sign in. nil = local-only.
    var appleUserID: String?

    /// Their referral code, cached from the backend.
    var referralCode: String?

    /// The id used for backend calls (Apple id once signed in, else a stable
    /// per-install id). Computed, never persisted.
    var backendUserID: String { appleUserID ?? InstallID.current }

    /// Last daily mood check-in (for the once-a-day reward).
    var lastCheckInDate: Date?

    /// Focus Yolks earned today + the day they apply to (for the daily cap).
    var focusEarnedToday: Int = 0
    var focusEarnedDate: Date?

    /// The day the "grow by living" bonus (steps/sleep → Yolks + rest) was last
    /// claimed, so it can only be collected once a day.
    var livingClaimDate: Date?

    /// Whether the player has connected Health (so the home card shows their day
    /// instead of the connect prompt).
    var healthConnected: Bool = false

    /// Whether the player opted into Screen Time (Family Controls), so the off-phone
    /// pillar reads their real time away instead of the gentle "soon" state.
    var screenTimeConnected: Bool = false

    /// How much the yolk trusts you (0...1). It rises ONLY when you take care of
    /// YOURSELF (check-ins, the grow-by-living bonus), never from petting it. At
    /// enough trust the yolk waves hello and warms up to you.
    var trust: Double = 0
    /// Whether we've shown the first-wave moment (so it lands once).
    var firstWaveShown: Bool = false
    /// The last day trust eased up. Trust is a CONSISTENCY read: only the first
    /// self-care action each day moves it, so showing up daily matters, not cramming.
    var lastTrustDate: Date?

    /// Whether the first-run home tour has been shown.
    var tutorialSeen: Bool = false

    /// Whether the one-time home-screen widget nudge has been shown (Task 4).
    var widgetNudgeShown: Bool = false

    /// Decorate-mode placement: zone.rawValue -> decor id. Optional + defaulted nil so
    /// it is SwiftData migration-safe. nil means "not migrated yet" (see placedDecor()).
    var placedDecorByZone: [String: String]? = nil

    var createdAt: Date

    init(
        name: String,
        colorHex: Int,
        styleRaw: String,
        startingMoodRaw: String,
        accentHex: Int? = nil,
        patternRaw: String = "none",
        coins: Int = 100,
        ownedItemIDs: [String] = [],
        equippedItemIDs: [String] = [],
        appleUserID: String? = nil,
        lastCheckInDate: Date? = nil,
        createdAt: Date = .now
    ) {
        self.lastCheckInDate = lastCheckInDate
        self.name = name
        self.colorHex = colorHex
        self.styleRaw = styleRaw
        self.startingMoodRaw = startingMoodRaw
        self.accentHex = accentHex
        self.patternRaw = patternRaw
        self.coins = coins
        self.ownedItemIDs = ownedItemIDs
        self.equippedItemIDs = equippedItemIDs
        self.appleUserID = appleUserID
        self.createdAt = createdAt
    }

    /// The pieces to actually display, one per occupied zone. On first run after the
    /// update (`placedDecorByZone == nil`), auto-place owned decor: one per zone, highest
    /// rarity wins ties, and persist so rooms are never empty post-update.
    @MainActor
    func placedDecor(ownedIDs: Set<String>) -> [RoomDecor.Zone: RoomDecor] {
        if let stored = placedDecorByZone {
            var out: [RoomDecor.Zone: RoomDecor] = [:]
            for (zoneRaw, id) in stored {
                guard let zone = RoomDecor.Zone(rawValue: zoneRaw),
                      let d = RoomDecorCatalog.byID(id), ownedIDs.contains(id) else { continue }
                out[zone] = d
            }
            return out
        }
        // Migrate: best owned piece per zone.
        var best: [RoomDecor.Zone: RoomDecor] = [:]
        for d in RoomDecorCatalog.all where ownedIDs.contains(d.id) {
            if let cur = best[d.zone], cur.rarity.rank >= d.rarity.rank { continue }
            best[d.zone] = d
        }
        placedDecorByZone = Dictionary(uniqueKeysWithValues: best.map { ($0.key.rawValue, $0.value.id) })
        return best
    }

    /// Place / swap / clear a single zone, then it is the caller's job to persist().
    @MainActor
    func setDecor(_ id: String?, in zone: RoomDecor.Zone) {
        var dict = placedDecorByZone ?? [:]
        if let id { dict[zone.rawValue] = id } else { dict[zone.rawValue] = nil }
        placedDecorByZone = dict
    }
}

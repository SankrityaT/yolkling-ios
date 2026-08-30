import SwiftUI
import YolklingCore

/// The publishable look of a player's creature + room, shared so a friend can VISIT
/// (see your "pet house"). Opaque jsonb on the server; the client owns the shape.
/// Mirrors the fields RootView uses to reconstruct a creature from a Player.
struct RoomSnapshot: Codable, Sendable {
    var colorHex: Int
    var styleRaw: String
    var accentHex: Int?
    var patternRaw: String
    var activeFoundingID: String?
    var moodRaw: String
    var themeID: String
    var decorIDs: [String]
    var outfitIDs: [String]
    var streak: Int?
    var hour: Int?

    init(colorHex: Int, styleRaw: String, accentHex: Int?, patternRaw: String,
         activeFoundingID: String?, moodRaw: String, themeID: String,
         decorIDs: [String], outfitIDs: [String], streak: Int? = nil, hour: Int? = nil) {
        self.colorHex = colorHex; self.styleRaw = styleRaw; self.accentHex = accentHex
        self.patternRaw = patternRaw; self.activeFoundingID = activeFoundingID
        self.moodRaw = moodRaw; self.themeID = themeID
        self.decorIDs = decorIDs; self.outfitIDs = outfitIDs
        self.streak = streak; self.hour = hour
    }
}

extension RoomSnapshot {
    /// Lenient decode: a friend who never published (or an empty `{}`) still yields a
    /// sensible default yolk in a cozy room instead of failing the whole list.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        colorHex = try c.decodeIfPresent(Int.self, forKey: .colorHex) ?? 0xFFC23B
        styleRaw = try c.decodeIfPresent(String.self, forKey: .styleRaw) ?? "classic"
        accentHex = try c.decodeIfPresent(Int.self, forKey: .accentHex)
        patternRaw = try c.decodeIfPresent(String.self, forKey: .patternRaw) ?? "none"
        activeFoundingID = try c.decodeIfPresent(String.self, forKey: .activeFoundingID)
        moodRaw = try c.decodeIfPresent(String.self, forKey: .moodRaw) ?? "happy"
        themeID = try c.decodeIfPresent(String.self, forKey: .themeID) ?? "room-cozy"
        decorIDs = try c.decodeIfPresent([String].self, forKey: .decorIDs) ?? []
        outfitIDs = try c.decodeIfPresent([String].self, forKey: .outfitIDs) ?? []
        streak = try c.decodeIfPresent(Int.self, forKey: .streak)
        hour = try c.decodeIfPresent(Int.self, forKey: .hour)
    }

    var theme: RoomTheme { RoomThemes.all.first { $0.id == themeID } ?? RoomThemes.cozy }
    var decor: [RoomDecor] { decorIDs.compactMap { RoomDecorCatalog.byID($0) } }
    var outfit: [Cosmetic] { outfitIDs.compactMap { id in CosmeticCatalog.all.first { $0.id == id } } }
    var expression: YolkExpression { (Mood(rawValue: moodRaw) ?? .happy).expression }

    /// Rebuild the friend's renderable creature (mirrors RootView.creature).
    func makeVibe(name: String) -> Vibe {
        if let fid = activeFoundingID, let sp = SpeciesCatalog.founding(id: fid) { return sp.vibe }
        let hex = UInt(colorHex)
        return Vibe(id: "friend", name: name, body: Color(hex: hex),
                    deep: Color(hex: CreaturePalette.darker(hex)),
                    style: CreatureStyle(rawValue: styleRaw) ?? .classic,
                    accent: accentHex.map { Color(hex: UInt($0)) },
                    pattern: BodyPattern(rawValue: patternRaw) ?? .none,
                    bodyStops: ColorShop.bodyStops(forBody: hex))
    }
}

/// A friend + their latest published room snapshot (from get_friends).
/// A pending swap offer. Always a SWAP — nothing in this app moves one-way, because a
/// one-way transfer is the one shape that lets an alt account farm seasonal items.
struct TradeOffer: Codable, Sendable, Identifiable {
    let id: Int
    let from_id: String
    let to_id: String
    let offer_item: String
    let want_item: String
    let status: String
    let incoming: Bool
    let other_name: String?

    var otherName: String { (other_name?.isEmpty == false ? other_name : nil) ?? "a friend" }

    /// What lands in YOUR wardrobe if this goes through.
    var youGet: String { incoming ? offer_item : want_item }
    /// What leaves it.
    var youGive: String { incoming ? want_item : offer_item }

    var cosmeticYouGet: Cosmetic? { CosmeticCatalog.all.first { $0.id == youGet } }
    var cosmeticYouGive: Cosmetic? { CosmeticCatalog.all.first { $0.id == youGive } }
}

/// A stranger's room your yolkling can drift into.
///
/// Shaped like `Friend` on purpose — same fields, same accessors — so `VisitView` can
/// render either without knowing which it has. The difference between them is what you
/// are ALLOWED to do, not what gets drawn.
struct DriftTarget: Codable, Sendable, Identifiable {
    let user_id: String
    let name: String?
    let snapshot: RoomSnapshot?
    var id: String { user_id }
    var displayName: String { (name?.isEmpty == false ? name : nil) ?? "someone" }
}

struct Friend: Codable, Sendable, Identifiable {
    let user_id: String
    let name: String?
    let snapshot: RoomSnapshot?
    var updated_at: String? = nil

    /// Species ids this friend has found. Defaulted, so a friend from an older server
    /// response (or a preview) decodes as "collection unknown" rather than failing.
    var found: [String]? = nil

    /// Their trust BAND, never their trust value.
    ///
    /// Trust is the most personal number in the app — a reading of how someone has been
    /// treating themselves — and publishing it to their friends would turn a private thing
    /// into a scoreboard. The band is already public in another form (it is the line under
    /// their creature in their room), so it can pick the right laminate for their card
    /// without anyone learning a figure about them.
    var trust_band: String? = nil

    var id: String { user_id }
    var displayName: String { (name?.isEmpty == false ? name : nil) ?? "a friend" }

    /// The middle of their band, purely to pick a material. Deliberately NOT a real trust
    /// value and never shown as one.
    var bandTrust: Double {
        switch trust_band {
        case "warming":   0.32
        case "friend":    0.57
        case "companion": 0.80
        case "devoted":   0.95
        default:          0.10
        }
    }
    var updatedDate: Date? {
        guard let s = updated_at else { return nil }
        return ISO8601DateFormatter().date(from: s)
    }
}

/// A received kind note (from get_postcards).
struct Postcard: Codable, Sendable, Identifiable {
    let id: Int
    let from_id: String
    let from_name: String?
    let message: String
    let created_at: String
    let read: Bool
    var senderName: String { (from_name?.isEmpty == false ? from_name : nil) ?? "a friend" }
}

/// Result of redeeming a friend code.
struct AddFriendResult: Sendable {
    let ok: Bool
    let friendID: String?
    let name: String?
    let reason: String?
}

/// A wave received from a friend (from get_waves). Marked seen on fetch.
struct Wave: Codable, Sendable, Identifiable {
    let from_id: String
    let name: String?
    let created_at: String
    var id: String { from_id }
    var senderName: String { (name?.isEmpty == false ? name : nil) ?? "a friend" }
}

/// A recent visit to your room (from get_recent_visits).
struct Visit: Codable, Sendable, Identifiable {
    let visitor_id: String
    let name: String?
    let created_at: String
    var id: String { visitor_id }
    var visitorName: String { (name?.isEmpty == false ? name : nil) ?? "a friend" }
}

import SwiftUI

/// The contract the iPhone app publishes to the watch app over WatchConnectivity
/// (`updateApplicationContext`). Same idea as `RoomSnapshot` (the friend-visit
/// contract in the app) but scoped to what the watch draws: the creature's
/// identity, its current mood, and the relationship line under it.
///
/// Lives in YolklingCore so BOTH sides speak the exact same type — the phone
/// encodes it, the watch decodes it, and the reconstruction below guarantees the
/// wrist shows the same creature as the phone.
public struct WatchCreatureSnapshot: Codable, Sendable {
    public var name: String
    public var colorHex: Int
    public var styleRaw: String
    public var accentHex: Int?
    public var patternRaw: String
    public var activeFoundingID: String?
    public var moodRaw: String
    public var outfitIDs: [String]
    public var trust: Double
    public var streak: Int

    public init(name: String, colorHex: Int, styleRaw: String, accentHex: Int?,
                patternRaw: String, activeFoundingID: String?, moodRaw: String,
                outfitIDs: [String], trust: Double, streak: Int) {
        self.name = name; self.colorHex = colorHex; self.styleRaw = styleRaw
        self.accentHex = accentHex; self.patternRaw = patternRaw
        self.activeFoundingID = activeFoundingID; self.moodRaw = moodRaw
        self.outfitIDs = outfitIDs; self.trust = trust; self.streak = streak
    }
}

public extension WatchCreatureSnapshot {
    /// The key the snapshot travels under in the WCSession application context
    /// dictionary (context values must be plist types, so the snapshot rides as Data).
    nonisolated static let contextKey = "yolk.watch.snapshot"

    /// Lenient decode, same policy as `RoomSnapshot`: the phone and watch app can be
    /// on different versions after an update, and a missing field should degrade to a
    /// sensible default yolk rather than fail the whole sync.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "your little guy"
        colorHex = try c.decodeIfPresent(Int.self, forKey: .colorHex) ?? 0xFFC23B
        styleRaw = try c.decodeIfPresent(String.self, forKey: .styleRaw) ?? "classic"
        accentHex = try c.decodeIfPresent(Int.self, forKey: .accentHex)
        patternRaw = try c.decodeIfPresent(String.self, forKey: .patternRaw) ?? "none"
        activeFoundingID = try c.decodeIfPresent(String.self, forKey: .activeFoundingID)
        moodRaw = try c.decodeIfPresent(String.self, forKey: .moodRaw) ?? "happy"
        outfitIDs = try c.decodeIfPresent([String].self, forKey: .outfitIDs) ?? []
        trust = try c.decodeIfPresent(Double.self, forKey: .trust) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
    }

    var mood: Mood { Mood(rawValue: moodRaw) ?? .happy }
    var expression: YolkExpression { mood.expression }
    var trustStage: TrustStage { TrustStage.from(trust: trust) }
    var outfit: [Cosmetic] { outfitIDs.compactMap { id in CosmeticCatalog.all.first { $0.id == id } } }

    /// Rebuild the renderable creature. Mirrors `RoomSnapshot.makeVibe` in the app —
    /// founding species win outright, otherwise colour + style + pattern, with `deep`
    /// derived from the body hex the same way every player colour derives it.
    var vibe: Vibe {
        if let fid = activeFoundingID, let sp = SpeciesCatalog.founding(id: fid) { return sp.vibe }
        let hex = UInt(colorHex)
        return Vibe(id: "watch", name: name, body: Color(hex: hex),
                    deep: Color(hex: CreaturePalette.darker(hex)),
                    style: CreatureStyle(rawValue: styleRaw) ?? .classic,
                    accent: accentHex.map { Color(hex: UInt($0)) },
                    pattern: BodyPattern(rawValue: patternRaw) ?? .none,
                    bodyStops: ColorShop.bodyStops(forBody: hex))
    }

    /// Encode for the application-context dictionary (and local caching on the watch).
    func encoded() -> Data? { try? JSONEncoder().encode(self) }

    static func decoded(from data: Data) -> WatchCreatureSnapshot? {
        try? JSONDecoder().decode(WatchCreatureSnapshot.self, from: data)
    }
}

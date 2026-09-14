import Foundation

/// A small, COMPLETABLE grouping of species to chase (the Zeigarnik / "gotta catch
/// em all" pull). The retention engine: you never lose what you have discovered,
/// the empty slots are what draw you back, and a seasonal set adds an honest clock
/// (you can MISS it, you never have it taken). See docs/MONETIZATION.md.
public struct SpeciesSet: Identifiable {
    public let id: String
    public let name: String
    public let blurb: String
    public let speciesIDs: [String]
    public let isSeasonal: Bool

    public init(id: String, name: String, blurb: String, speciesIDs: [String], isSeasonal: Bool = false) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.speciesIDs = speciesIDs
        self.isSeasonal = isSeasonal
    }

    public var species: [Species] { speciesIDs.compactMap { id in SpeciesCatalog.all.first { $0.id == id } } }

    /// Days left in this set's seasonal window, or nil if the set isn't seasonal or no
    /// window is currently running.
    ///
    /// This previously returned days-left-in-the-current-calendar-month *unconditionally*,
    /// so `spring-bloom` read as "in season" in November — and `DiscoveryEngine.pickNext`
    /// applied its 65% seasonal bias all year round. A season is a real, bounded window
    /// or it isn't a season.
    public func seasonDaysLeft(window: DateInterval?, now: Date = Date()) -> Int? {
        guard isSeasonal, let window, window.contains(now) else { return nil }
        return Calendar.current.dateComponents([.day], from: now, to: window.end).day
    }
}

/// Where a season's live window comes from.
///
/// Seasons are server-driven so one can open without shipping a build. This reads a
/// plain UserDefaults cache rather than talking to `EventStore` directly, and that
/// indirection is load-bearing: `SpeciesSet` is compiled into the WIDGET target, which
/// must never pull in networking. `EventStore` writes; this only reads, so the coupling
/// stays one-directional and the widget can show season state too.
public enum SeasonWindows {
    private static let key = "yolk.seasonWindows"   // [payloadID: [start, end] epochs]

    public static func window(for setID: String) -> DateInterval? {
        guard let raw = UserDefaults.standard.dictionary(forKey: key) as? [String: [Double]],
              let pair = raw[setID], pair.count == 2, pair[1] > pair[0] else { return nil }
        return DateInterval(start: Date(timeIntervalSince1970: pair[0]),
                            end: Date(timeIntervalSince1970: pair[1]))
    }

    /// Called by `EventStore` after every successful refresh.
    ///
    /// Takes plain values rather than `[SeasonalEvent]` on purpose: this file compiles
    /// into the widget target and `SeasonalEvent` does not, so naming that type here
    /// would break the widget build.
    public static func publish(_ windows: [String: DateInterval]) {
        let out = windows.mapValues { [$0.start.timeIntervalSince1970, $0.end.timeIntervalSince1970] }
        UserDefaults.standard.set(out, forKey: key)
    }
}

public enum SpeciesSets {
    /// New players start with these already discovered (endowed progress, with a
    /// stated reason in the UI: "week-one gift"). Without a reason the effect dies.
    public static let headStart: [String] = ["celestial-stardrop", "garden-sprig", "ocean-guppy"]

    public static let all: [SpeciesSet] = [
        SpeciesSet(id: "first-friends", name: "first friends",
                   blurb: "the gentle ones who show up early.",
                   speciesIDs: ["celestial-stardrop", "garden-sprig", "ocean-guppy", "cozy-mochi", "garden-clovi", "celestial-moonpuff"]),
        SpeciesSet(id: "spring-bloom", name: "spring bloom",
                   blurb: "here for a little while only.", isSeasonalSet: true,
                   speciesIDs: ["garden-tulipa", "garden-crocus", "garden-bluebell", "garden-peony", "garden-firefleur", "celestial-dawnberry"]),
        SpeciesSet(id: "night-sky", name: "night sky",
                   blurb: "small lights for the late hours.",
                   speciesIDs: ["celestial-stardrop", "celestial-sunny yolkstar", "celestial-ringling", "celestial-auroria", "celestial-lilac comet", "celestial-galaxia"]),
        SpeciesSet(id: "garden-patch", name: "garden patch",
                   blurb: "everything that grows soft and slow.",
                   speciesIDs: ["garden-sprig", "garden-clovi", "garden-daisette", "garden-capling", "garden-beelle", "garden-ladypip", "garden-fourleaf"]),
        SpeciesSet(id: "tide-pool", name: "tide pool",
                   blurb: "found near the quiet water.",
                   speciesIDs: ["ocean-guppy", "ocean-pearlpup", "ocean-coralla", "ocean-starlet", "ocean-jellybean", "ocean-leviabelle"]),
        SpeciesSet(id: "cozy-corner", name: "the cozy corner",
                   blurb: "the warmest, softest, most huggable.",
                   speciesIDs: ["cozy-mochi", "cozy-matcha cream", "cozy-marshmallow", "cozy-cocoa", "cozy-honeydrop", "cozy-goldenhoney"]),
    ]
}

private extension SpeciesSet {
    init(id: String, name: String, blurb: String, isSeasonalSet: Bool, speciesIDs: [String]) {
        self.init(id: id, name: name, blurb: blurb, speciesIDs: speciesIDs, isSeasonal: isSeasonalSet)
    }
}

// MARK: - Dex numbering

extension SpeciesSets {
    /// Every species reachable through play, in a stable order.
    ///
    /// The Dex universe is the WHOLE CATALOG, minus the founding species, which are
    /// grants rather than finds and correctly print no serial.
    ///
    /// It used to be the union of the six sets, which was 32 of the 203 drawn species.
    /// The reasoning was sound at the time -- a card must not print a denominator the
    /// player cannot reach -- but the conclusion was backwards: the fix is to make the
    /// rest reachable, not to hide them. 171 species had names, art, rarities and
    /// descriptions, and nothing in the app could ever hand one to you. After 32
    /// check-ins discovery returned nil forever.
    ///
    /// The sets remain, as curated collections with their own progress. They are a view
    /// onto the Dex now rather than the definition of it.
    ///
    /// Sorted, so a species' number is a property of the species rather than of the order
    /// the catalog happens to be declared in.
    public static let dex: [String] = SpeciesCatalog.standard.map(\.id).sorted()

    public static var dexTotal: Int { dex.count }

    /// A card's printed number, 1-based. `nil` for a species outside the Dex (a founding
    /// grant, say), which correctly prints no serial at all rather than a made-up one.
    public static func dexNumber(of speciesID: String) -> Int? {
        dex.firstIndex(of: speciesID).map { $0 + 1 }
    }
}

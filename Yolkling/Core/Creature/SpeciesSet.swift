import Foundation

/// A small, COMPLETABLE grouping of species to chase (the Zeigarnik / "gotta catch
/// em all" pull). The retention engine: you never lose what you have discovered,
/// the empty slots are what draw you back, and a seasonal set adds an honest clock
/// (you can MISS it, you never have it taken). See docs/MONETIZATION.md.
struct SpeciesSet: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let speciesIDs: [String]
    let isSeasonal: Bool

    init(id: String, name: String, blurb: String, speciesIDs: [String], isSeasonal: Bool = false) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.speciesIDs = speciesIDs
        self.isSeasonal = isSeasonal
    }

    var species: [Species] { speciesIDs.compactMap { id in SpeciesCatalog.all.first { $0.id == id } } }

    /// Days left in a seasonal window (this calendar month). nil for evergreen sets.
    var seasonDaysLeft: Int? {
        guard isSeasonal else { return nil }
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: Date()) else { return nil }
        return cal.dateComponents([.day], from: Date(), to: interval.end).day
    }
}

enum SpeciesSets {
    /// New players start with these already discovered (endowed progress, with a
    /// stated reason in the UI: "week-one gift"). Without a reason the effect dies.
    static let headStart: [String] = ["celestial-stardrop", "garden-sprig", "ocean-guppy"]

    static let all: [SpeciesSet] = [
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

import SwiftUI

// docs/species/ocean.md, transcribed. Tide-pool creatures: fish, shells, coral,
// jellies, pearls, lanterns. Eye column omitted (eyes follow mood).
extension SpeciesCatalog {
    public static let ocean: [Species] = [
        o("guppy", .common, 0xBFE7E0, 0x7FC2BC, nil, .dorsalFin, .scaleSpeckle, "a wiggly little starter fish, always first to the food bowl"),
        o("minnow", .common, 0xCDEAF2, 0x8FBFD8, nil, .dorsalFin, .bubbleDots, "small, fast, easily delighted by literally anything"),
        o("puddle", .common, 0xC9E8E2, 0x93C9BE, nil, .classic, .pearlBelly, "a calm drop of pond, content to just sit and shimmer"),
        o("dewfish", .common, 0xD6EFE6, 0x9AD0BE, nil, .finFan, .seafoamFreckles, "morning-fresh and a bit dewy-eyed, loves a slow start"),
        o("tadpole", .common, 0xC3E2D6, 0x84B79E, nil, .tuft, .waveStripe, "not sure what it'll grow into yet, optimistic about it"),
        o("pebbleperch", .common, 0xDDE3D2, 0xA9B193, nil, .classic, .scaleSpeckle, "a sandy riverbed sitter, steady and unbothered"),
        o("sandyfin", .common, 0xEAD9B8, 0xC2A876, nil, .dorsalFin, .waveStripe, "warm shallows kid, always a little sun-toasted"),
        o("brine", .common, 0xB7D8DC, 0x7FACB3, nil, .finFan, .bubbleDots, "tangy little tidepool gremlin, surprisingly sweet"),
        o("ripple", .common, 0xC6E6EE, 0x8CBED2, nil, .waveCrest, .waveStripe, "leaves tiny rings wherever it goes, can't sit still"),
        o("froth", .common, 0xE4F1EE, 0xB2D4CC, nil, .waveCrest, .bubbleDots, "mostly foam and giggles, dissolves into laughter"),
        o("seaspray", .common, 0xD2ECEC, 0x9BCAC8, nil, .bubbleCluster, .seafoamFreckles, "bubbly to a fault, narrates its own adventures"),
        o("spritzle", .common, 0xCFEFF4, 0x95CDD6, 0xCFEFF4, .bubbleCluster, .bubbleDots, "a fizzy soda of a fish, all pop and sparkle"),
        o("pearlpup", .rare, 0xF7EFE2, 0xD8C7A8, 0xF7EFE2, .pearlTiara, .pearlBelly, "soft and lustrous, treats everyone like royalty"),
        o("nacre", .rare, 0xF2EFE6, 0xCFC6B0, 0xF7EFE2, .pearlTiara, .pearlBelly, "quietly elegant, hums to itself in mother-of-pearl"),
        o("oysterling", .rare, 0xE6E1D4, 0xB9AE95, 0xF7EFE2, .seashell, .pearlBelly, "a homebody who keeps its treasures very close"),
        o("cocklewho", .rare, 0xEDD9CE, 0xC49F8C, nil, .seashell, .scaleSpeckle, "nosy little scallop, collects gossip like sand"),
        o("conchita", .rare, 0xF4DCC9, 0xCFA286, nil, .seashell, .waveStripe, "hold it up to your ear and you hear the whole sea"),
        o("coralla", .rare, 0xF6C9BF, 0xE08C82, 0xF2A6A0, .coralSprig, .seafoamFreckles, "grows a little prettier the longer you love it"),
        o("reefling", .rare, 0xF2B7AE, 0xD98079, 0xF2A6A0, .coralSprig, .scaleSpeckle, "builds tiny cozy nooks for smaller creatures"),
        o("poppyreef", .rare, 0xFBC4B4, 0xE89684, 0xF7B8B0, .coralSprig, .bubbleDots, "bright and branching, hosts the whole neighbourhood"),
        o("starlet", .rare, 0xF6B27A, 0xD98E52, 0xF6B27A, .starfishCrown, .scaleSpeckle, "five-pointed and fabulous, regrows from any setback"),
        o("seastarla", .rare, 0xF2A95E, 0xC97E3C, 0xF6B27A, .starfishCrown, .seafoamFreckles, "slow and deliberate, gets there exactly when needed"),
        o("dapplefin", .rare, 0xC8E4D8, 0x8DB9A6, nil, .dorsalFin, .scaleSpeckle, "speckled like sun through shallow water, very chill"),
        o("glimmerguppy", .rare, 0xCDEBE6, 0x8EC6BD, 0xFFF6C9, .dorsalFin, .bubbleDots, "catches every glint of light and shows it off"),
        o("tidetuft", .rare, 0xBCDDE8, 0x82B4C6, nil, .waveCrest, .tidalGradientBand, "wears the sea like a quiff, moody in a gentle way"),
        o("foamcrest", .rare, 0xE0EFEC, 0xABCFC6, nil, .waveCrest, .pearlBelly, "the friendly wave that always rolls back for you"),
        o("snorkelpip", .rare, 0xC4E2EE, 0x86B6CC, 0xF2A6A0, .finFan, .bubbleDots, "suited up and ready, narrates the reef tour for free"),
        o("anemonia", .rare, 0xD8C2E0, 0xA988BC, 0xF2A6A0, .coralSprig, .seafoamFreckles, "sways softly and hugs back, surprisingly clingy"),
        o("kelpkin", .rare, 0xA9CBA0, 0x729B6A, 0x7FB98C, .sprout, .waveStripe, "a forest-of-the-sea kid, trails greenery everywhere"),
        o("seagrasling", .rare, 0xB7CF9C, 0x82A064, 0x9AD0A2, .sprout, .seafoamFreckles, "meadow-minded, sways with currents most can't feel"),
        o("jellybean", .epic, 0xD7C2EC, 0xA988CC, 0xD7C2EC, .jellyTendrils, .bubbleDots, "drifts wherever the day takes it, soft and weightless"),
        o("moonjelly", .epic, 0xDCD2EE, 0xB0A4D6, 0xD7C2EC, .jellyTendrils, .pearlBelly, "glows faint and pale, keeps the late, quiet hours"),
        o("lumijelly", .epic, 0xC9D6F0, 0x95A6D6, 0xE3D6F2, .jellyTendrils, .tidalGradientBand, "bioluminescent dreamer, blinks in slow morse code"),
        o("bloomjelly", .epic, 0xF0C7DE, 0xD690B4, 0xD7C2EC, .jellyTendrils, .seafoamFreckles, "trails ribbons of colour, falls in love constantly"),
        o("lanternlot", .epic, 0xFFE3A8, 0xE0B25E, 0xFFE08A, .anglerLantern, .tidalGradientBand, "carries a tiny light so nobody's path goes dark"),
        o("deepglow", .epic, 0x9FB6CC, 0x647F9E, 0xFFE08A, .anglerLantern, .pearlBelly, "lives where it's quiet and deep, gentle and warm"),
        o("abysscot", .epic, 0x8FA6C0, 0x586F8E, 0xFFF6C9, .anglerLantern, .tidalGradientBand, "far down and unhurried, befriends the lonely dark"),
        o("pearl-of-tides", .legendary, 0xFBF3E6, 0xDCC9A4, 0xF7EFE2, .pearlTiara, .pearlBelly, "a single perfect pearl given a heartbeat, utterly serene"),
        o("coralqueen", .legendary, 0xF7B5A6, 0xD87A6C, 0xF2A6A0, .coralSprig, .scaleSpeckle, "the whole reef leans toward her, ancient and kind"),
        o("leviabelle", .legendary, 0x7FA8C4, 0x4E7396, 0xFFE08A, .anglerLantern, .tidalGradientBand, "the gentle giant of the deep, a lighthouse with fins"),
    ]

    private static func o(_ name: String, _ rarity: Species.Rarity, _ b: UInt, _ d: UInt, _ a: UInt?,
                          _ style: CreatureStyle, _ pattern: BodyPattern, _ p: String) -> Species {
        Species(id: "ocean-" + name, name: name, family: "ocean", rarity: rarity,
                bodyHex: b, deepHex: d, accentHex: a, style: style, pattern: pattern, personality: p)
    }
}

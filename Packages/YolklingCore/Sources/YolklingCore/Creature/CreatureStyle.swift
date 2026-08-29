import Foundation

/// A base "look" for a yolkling: the TOP FEATURE drawn above the head, part of
/// its IDENTITY (alongside colour + `BodyPattern`). All rendered in code (see
/// `CreatureParts.swift`), so adding a look is adding a case, not an art asset.
///
/// `allCases` is the full taxonomy of features (used by the species catalogue and
/// the gallery). Onboarding shows only `starters`, a small curated set, so the
/// creation picker stays simple.
public enum CreatureStyle: String, CaseIterable, Sendable, Identifiable {
    // base looks (the original starters)
    case classic   // just the round body
    case ears      // two little rounded ears
    case sprout    // a small leaf sprout on top
    case tuft      // a single curl of hair

    // celestial family
    case starAntenna, twinAntennae, crescentTuft, ringHalo, sunRays
    case comet, aurora, constellation, nebula, orbitDot

    // garden family
    case tulipBud, daisyCrown, singlePetalFlower, mushroomCap, cloverTop, antennae
    case beeAntennae, berryCluster, leafPair, bellFlower, sproutTrio, acornCap

    // ocean family
    case dorsalFin, seashell, bubbleCluster, coralSprig, waveCrest
    case jellyTendrils, starfishCrown, pearlTiara, anglerLantern, finFan

    // cozy family
    case creamSwirl, knitBobble, creamDollop, steamWisp, marshmallowTuft
    case foldedDoughEars, cherryOnTop, honeyDrip, teacupSteam, fuzzyWoolTuft

    public var id: String { rawValue }

    /// The small curated set offered at creation. The rest are reached by
    /// hatching into a species or via grants.
    public static let starters: [CreatureStyle] = [.classic, .ears, .sprout, .tuft, .starAntenna, .crescentTuft]

    public var label: String {
        switch self {
        case .classic:       "classic"
        case .ears:          "ears"
        case .sprout:        "sprout"
        case .tuft:          "tuft"
        case .starAntenna:   "star"
        case .twinAntennae:  "twin stars"
        case .crescentTuft:  "crescent"
        case .ringHalo:      "ringed"
        case .sunRays:       "sunny"
        case .comet:         "comet"
        case .aurora:        "aurora"
        case .constellation: "constellation"
        case .nebula:        "nebula"
        case .orbitDot:      "orbit"
        case .tulipBud:          "tulip"
        case .daisyCrown:        "daisy"
        case .singlePetalFlower: "bloom"
        case .mushroomCap:       "mushroom"
        case .cloverTop:         "clover"
        case .antennae:          "antennae"
        case .beeAntennae:       "bee"
        case .berryCluster:      "berries"
        case .leafPair:          "leaves"
        case .bellFlower:        "bluebell"
        case .sproutTrio:        "grassy"
        case .acornCap:          "acorn"
        case .dorsalFin:         "fin"
        case .seashell:          "shell"
        case .bubbleCluster:     "bubbles"
        case .coralSprig:        "coral"
        case .waveCrest:         "wave"
        case .jellyTendrils:     "jelly"
        case .starfishCrown:     "starfish"
        case .pearlTiara:        "pearls"
        case .anglerLantern:     "lantern"
        case .finFan:            "fan fin"
        case .creamSwirl:        "cream"
        case .knitBobble:        "bobble"
        case .creamDollop:       "dollop"
        case .steamWisp:         "steam"
        case .marshmallowTuft:   "marshmallow"
        case .foldedDoughEars:   "dough"
        case .cherryOnTop:       "cherry"
        case .honeyDrip:         "honey"
        case .teacupSteam:       "teacup"
        case .fuzzyWoolTuft:     "wool"
        }
    }
}

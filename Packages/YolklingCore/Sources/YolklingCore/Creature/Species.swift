import SwiftUI

/// One named creature in the taxonomy: a palette + top feature + body pattern,
/// plus flavour. A `Species` builds a `Vibe` (its identity) that any view can
/// render. Data is transcribed from docs/species/*.md. Founding species are
/// grant-only (see docs/species/founding.md).
public struct Species: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let family: String
    public let rarity: Rarity
    public let bodyHex: UInt
    public let deepHex: UInt
    public let accentHex: UInt?
    public let style: CreatureStyle
    public let pattern: BodyPattern
    public let personality: String
    public var flair: FoundingFlair? = nil

    public init(id: String, name: String, family: String, rarity: Rarity,
                bodyHex: UInt, deepHex: UInt, accentHex: UInt?,
                style: CreatureStyle, pattern: BodyPattern, personality: String,
                flair: FoundingFlair? = nil) {
        self.id = id; self.name = name; self.family = family; self.rarity = rarity
        self.bodyHex = bodyHex; self.deepHex = deepHex; self.accentHex = accentHex
        self.style = style; self.pattern = pattern; self.personality = personality
        self.flair = flair
    }

    public enum Rarity: String, Sendable, CaseIterable {
        case common, rare, epic, legendary, founding
    }

    public var vibe: Vibe {
        Vibe(id: id, name: name,
             body: Color(hex: bodyHex), deep: Color(hex: deepHex),
             style: style,
             accent: accentHex.map { Color(hex: $0) },
             pattern: pattern,
             flair: flair)
    }
}

/// The full taxonomy, grouped by family. Families are added as their specs are
/// ported (docs/species/*.md). The combinatorial space of features x patterns x
/// palettes backs the "912 species" claim; these are the curated, named ones.
public enum SpeciesCatalog {
    public static var all: [Species] { celestial + garden + ocean + cozy }

    /// All non-founding species, the ones reachable through normal play.
    public static var standard: [Species] { all.filter { $0.rarity != .founding } }

    /// Look up a founding species by its grant id (e.g. "founding-the og").
    public static func founding(id: String) -> Species? { founding.first { $0.id == id } }

    // docs/species/celestial.md
    public static let celestial: [Species] = [
        c("stardrop", .common, 0xFBE6A8, 0xE7C25E, 0xFFF4C9, .starAntenna, .starFreckles, "the cheerful first wish of the night"),
        c("lilac comet", .rare, 0xC9B8E8, 0x9A82C9, 0xFFD9B0, .comet, .moonDust, "always arriving a little out of breath"),
        c("moonpuff", .common, 0xE8E2D2, 0xC2BAA6, 0xFBF1C9, .crescentTuft, .crescentBelly, "naps through every sunrise on purpose"),
        c("sunny yolkstar", .common, 0xFFD98C, 0xF0B23E, 0xFFE9A8, .sunRays, .twilightBand, "wakes the whole sky up by being loud"),
        c("dusk plum", .rare, 0xA99BCF, 0x7C6BA8, 0xF2B6C6, .aurora, .twilightBand, "likes the quiet ten minutes after sunset"),
        c("ringling", .epic, 0xBCCBE8, 0x8AA0CC, 0xE9C77A, .ringHalo, .orbitRings, "wears its own little rings, proudly"),
        c("starnap", .common, 0xD7C8E8, 0xA98FCC, 0xFFE2A6, .crescentTuft, .starFreckles, "counts stars until it forgets which it was on"),
        c("auroria", .epic, 0xA7D8D0, 0x6FAFA8, 0xC8A6E8, .aurora, .galaxySwirl, "shy, but glows softly when it is happy"),
        c("nebulina", .epic, 0xC4A9D6, 0x8E6FB0, 0xF0AFC4, .nebula, .galaxySwirl, "dreams in slow swirling colours"),
        c("pip the small star", .common, 0xFFEFC2, 0xE9CC78, 0xFFFBE9, .starAntenna, .starFreckles, "tiny, bright, certain it is very important"),
        c("twinkleberry", .common, 0xF4C6D6, 0xD98FAC, 0xFFE3A8, .twinAntennae, .starFreckles, "giggles in little sparkles when tickled"),
        c("midnight bao", .rare, 0x8E9BC4, 0x5E6B98, 0xE8D08A, .constellation, .moonDust, "soft, round, and full of quiet midnight"),
        c("solune", .rare, 0xFFE0A6, 0xE8B05E, 0xB9A6E0, .sunRays, .crescentBelly, "half daydream, half afternoon sun"),
        c("cometail", .rare, 0xB6C7E8, 0x8298C9, 0xFFC79A, .comet, .orbitRings, "leaves a glittery trail everywhere it goes"),
        c("haloh", .rare, 0xF0E6C9, 0xCCB888, 0xFFF0BE, .ringHalo, .moonDust, "so well behaved a halo just appears"),
        c("starling jr", .common, 0xFBE3B0, 0xE6BE68, 0xFFF6D2, .constellation, .starFreckles, "practicing being a whole constellation"),
        c("violetwink", .rare, 0xB79CE0, 0x8C6CC4, 0xFFD7E2, .twinAntennae, .galaxySwirl, "winks one star at a time, very deliberately"),
        c("peachorbit", .rare, 0xFAD2B4, 0xE8A878, 0xC7B2E8, .orbitDot, .orbitRings, "one tiny moon and it loves that moon dearly"),
        c("lullamoon", .common, 0xDCD6E8, 0xABA2C9, 0xF5DFA8, .crescentTuft, .crescentBelly, "hums you to sleep and falls asleep first"),
        c("glimmerbit", .common, 0xFFF1CC, 0xEAD183, 0xFFFDEF, .starAntenna, .moonDust, "so shiny it is hard to look directly at"),
        c("dawnberry", .common, 0xFBC9C0, 0xE8978E, 0xFFE2A0, .sunRays, .twilightBand, "the soft pink before the sun is fully up"),
        c("eclipsi", .epic, 0x9A93B0, 0x6A6385, 0xFFE9A8, .crescentTuft, .crescentBelly, "quiet and rare, like the moment of eclipse"),
        c("starwhisper", .rare, 0xC7D8E0, 0x93AEBC, 0xE8C089, .aurora, .starFreckles, "tells secrets only the constellations hear"),
        c("cozmo", .epic, 0xA6B8E0, 0x768CC4, 0xFFD08A, .ringHalo, .orbitRings, "a tiny gas giant with a very big heart"),
        c("sprinklestar", .common, 0xFBD9E2, 0xE89CB6, 0xFFF0C2, .twinAntennae, .starFreckles, "scatters happy sparkles when it bounces"),
        c("moonbean", .common, 0xEDE7D0, 0xC8BE9A, 0xD9C2F0, .crescentTuft, .moonDust, "a little bean that came back from the moon"),
        c("auroric", .epic, 0x9CD0C4, 0x65A89A, 0xE0B0F0, .aurora, .galaxySwirl, "ripples with soft green and violet light"),
        c("stargazel", .rare, 0xD2C4E8, 0xA286C9, 0xFFE0A8, .constellation, .starFreckles, "tilts its head back to find new stars"),
        c("sunkit", .common, 0xFFD27A, 0xEAA63A, 0xFFEDB0, .sunRays, .crescentBelly, "a small warm sunbeam in creature form"),
        c("cinderstar", .rare, 0xE8C9A8, 0xC99A6E, 0xFFE7B0, .comet, .starFreckles, "a warm ember drifting up into the dark"),
        c("periwink", .common, 0xB9C2E8, 0x8794C9, 0xFFD9C2, .twinAntennae, .orbitRings, "periwinkle blue and perpetually winking"),
        c("galaxia", .legendary, 0xB098D0, 0x7E60AC, 0xF2A9C6, .nebula, .galaxySwirl, "holds a whole tiny galaxy in its belly"),
        c("lunette", .common, 0xE2DCEC, 0xB2A8CC, 0xFBE6A0, .crescentTuft, .crescentBelly, "a small soft moon that fits in your hands"),
        c("brightnel", .common, 0xFFF3D0, 0xECD68A, 0xFFFCEE, .starAntenna, .moonDust, "the brightest little night-light there is"),
        c("stormnova", .epic, 0x94A0C4, 0x636F98, 0xFFCF8E, .comet, .galaxySwirl, "quiet now, but it remembers being a nova"),
        c("dewstar", .common, 0xCDE2DE, 0x9AC0BA, 0xE8C68C, .constellation, .moonDust, "a star that landed in the morning dew"),
        c("ambermoon", .rare, 0xF0CE9A, 0xD29E5E, 0xB8A4E0, .crescentTuft, .twilightBand, "the warm gold moon of a late harvest"),
        c("pixiebeam", .common, 0xF6CFE2, 0xDC96B8, 0xFFF0C4, .starAntenna, .starFreckles, "a beam of pink starlight with opinions"),
        c("voidling", .epic, 0x8A86A6, 0x5C5880, 0xC8B4F0, .nebula, .moonDust, "gentle, soft-spoken, made of cozy dark"),
        c("solstice", .rare, 0xFFDFA0, 0xE8B458, 0xE0BCF0, .sunRays, .orbitRings, "the longest, sunniest, happiest day"),
        c("meteorling", .common, 0xD0C0B0, 0xA28E78, 0xFFD98C, .comet, .starFreckles, "a little falling star you got to keep"),
        c("celestine", .epic, 0xBFD0E8, 0x8FA8CC, 0xF4C6D2, .ringHalo, .orbitRings, "calm, pale blue, and quietly luminous"),
        c("twinklepea", .common, 0xDCE8C0, 0xB0C488, 0xE8C2F0, .twinAntennae, .galaxySwirl, "a sweet pea that grew under starlight"),
        c("nocturne", .rare, 0x9690B8, 0x645E8C, 0xFFE3A6, .crescentTuft, .crescentBelly, "the gentle song the night hums to itself"),
        c("sunpetal", .common, 0xFFE4B0, 0xECBC68, 0xF0C0D8, .sunRays, .crescentBelly, "unfolds toward any bit of warm light"),
        c("cosmolette", .rare, 0xC8B2E8, 0x9874C9, 0xFFD2B8, .nebula, .galaxySwirl, "a small swirl of cosmos in a comfy shape"),
        c("starbun", .common, 0xFBEAC8, 0xE6C988, 0xFFF8E0, .starAntenna, .starFreckles, "round as a bun and twice as warm"),
        c("aurelune", .legendary, 0xE6DDE8, 0xBBAACC, 0xFFE0AE, .crescentTuft, .twilightBand, "the rare gold-lit moon seen once a year"),
    ]

    private static func c(_ name: String, _ rarity: Species.Rarity, _ b: UInt, _ d: UInt, _ a: UInt?,
                          _ style: CreatureStyle, _ pattern: BodyPattern, _ p: String) -> Species {
        Species(id: "celestial-" + name, name: name, family: "celestial", rarity: rarity,
                bodyHex: b, deepHex: d, accentHex: a, style: style, pattern: pattern, personality: p)
    }
}

import Foundation

/// A worn cosmetic — the "costume" layer, separate from the creature's base
/// `CreatureStyle`. Pure value type so it can be cached, synced, and (later)
/// loaded from the open-source SVG catalog. See docs/COSMETICS.md.
struct Cosmetic: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let name: String
    let slot: CosmeticSlot
    let kind: Kind
    let rarity: Rarity
    let cost: Int   // coins; 0 = free starter

    /// Grant-only: never in the shop, never buyable at any price.
    ///
    /// This is what creates a have/have-not gradient. Everything else is purchasable by
    /// anyone with enough earned Yolks, so it carries no signal — one hat is as
    /// obtainable as another. A seasonal item you can ONLY get by being there while the
    /// season ran is the first thing in this app worth wanting from someone else, which
    /// is the precondition for trading meaning anything.
    ///
    /// Note `cost: 0` cannot express this: Wallet unions every zero-cost item into
    /// `owned` as a free starter, so a cost of 0 would hand these to everybody.
    var grantOnly: Bool = false

    /// Today: a built-in code renderer. Later gains `.svg(url)` / `.lottie(url)`
    /// so community items slot in without changing equip/shop logic.
    enum Kind: String, Codable, Sendable {
        case beanie, partyHat, crown, gradCap, flowerCrown   // hat (originals)
        case chunkyBeanie, catEars, bunnyEars, bearEars, foxEars, strawberryHat
        case mushroomHat, santaHat, witchHat, topHat, beret, bowOnHead   // hat (batch 1)
        case bobbleHat, earflapHat, leafHat, singleFlower, snowHat
        case friedEggHat, pumpkinHat, acornCap, bucketHat                // hat (batch 2a)
        case cupcakeHat, wizardHat, chefHat, cowboyHat, headphones
        case tiara, littleHorns, softHalo, propellerCap                  // hat (batch 2b)
        case roundGlasses, sunglasses, starShades            // eyes (originals)
        case roundReadingGlasses, squareGlasses, catEyeGlasses, halfMoonGlasses, heartGlasses
        case aviatorSunglasses, roundSunglasses, visorShades, monocle, threeDGlasses
        case swimGoggles, sleepMask, dominoMask, eyepatch, sparkleEyes
        case eyebrows, unibrow, googlyEyes, eyeFlower, freckles, faceGem   // eyes (new)
        case bow, scarf, bowtie                              // neck (originals)
        case knitScarf, stripedScarf, chunkyCowl, infinityScarf, dapperBowtie
        case polkaBowtie, necktie, bandana, bellCollar, ruffCollar
        case pearlNecklace, pendantNecklace, starPendant, flowerLei, cape
        case medalRibbon, locket, babyBib, backpackStrap, sash   // neck (new)

        // spring bloom season — grant-only, see CosmeticView+Spring.swift
        case blossomCrown, butterflyPerch, wateringCan           // hat
        case petalLashes                                          // eyes
        case rainCape, cloverChain                                // neck

        /// Cosmetics that drape behind the body (drawn before the body circle in
        /// YolklingView), so a cape falls behind the yolk instead of covering it.
        var rendersBehindBody: Bool { self == .cape }
    }
}

/// The layer a cosmetic occupies (Bitmoji-style stacking). `anchorY` is the
/// vertical placement relative to the creature size (0 = body centre).
enum CosmeticSlot: String, CaseIterable, Codable, Sendable, Identifiable {
    case hat, eyes, neck

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hat:  "hats"
        case .eyes: "eyes"
        case .neck: "neck"
        }
    }

    var anchorY: CGFloat {
        switch self {
        case .hat:  -0.5
        case .eyes: -0.08
        case .neck:  0.3
        }
    }
}

enum Rarity: String, Codable, Sendable {
    case common, rare, epic
}

/// The built-in starter catalog. A wide range across slots; the open-source
/// SVG pipeline expands this without code changes (see docs/COSMETICS.md).
enum CosmeticCatalog {
    static let all: [Cosmetic] = [
        // hats
        Cosmetic(id: "beanie",     name: "Beanie",       slot: .hat,  kind: .beanie,       rarity: .common, cost: 0),
        Cosmetic(id: "party-hat",  name: "Party Hat",    slot: .hat,  kind: .partyHat,     rarity: .common, cost: 120),
        Cosmetic(id: "grad-cap",   name: "Grad Cap",     slot: .hat,  kind: .gradCap,      rarity: .rare,   cost: 300),
        Cosmetic(id: "flower",     name: "Flower Crown", slot: .hat,  kind: .flowerCrown,  rarity: .rare,   cost: 300),
        Cosmetic(id: "crown",      name: "Crown",        slot: .hat,  kind: .crown,        rarity: .epic,   cost: 500),
        // batch 1 hats (docs/cosmetics/hats.md)
        Cosmetic(id: "chunky-beanie", name: "Chunky Beanie", slot: .hat, kind: .chunkyBeanie, rarity: .common, cost: 0),
        Cosmetic(id: "cat-ears",   name: "Cat Ears",     slot: .hat,  kind: .catEars,      rarity: .common, cost: 120),
        Cosmetic(id: "bunny-ears", name: "Bunny Ears",   slot: .hat,  kind: .bunnyEars,    rarity: .common, cost: 120),
        Cosmetic(id: "bear-ears",  name: "Bear Ears",    slot: .hat,  kind: .bearEars,     rarity: .common, cost: 120),
        Cosmetic(id: "fox-ears",   name: "Fox Ears",     slot: .hat,  kind: .foxEars,      rarity: .rare,   cost: 250),
        Cosmetic(id: "strawberry", name: "Strawberry",   slot: .hat,  kind: .strawberryHat, rarity: .rare,  cost: 280),
        Cosmetic(id: "mushroom-hat", name: "Mushroom",   slot: .hat,  kind: .mushroomHat,  rarity: .rare,   cost: 280),
        Cosmetic(id: "santa-hat",  name: "Santa Hat",    slot: .hat,  kind: .santaHat,     rarity: .rare,   cost: 300),
        Cosmetic(id: "witch-hat",  name: "Witch Hat",    slot: .hat,  kind: .witchHat,     rarity: .rare,   cost: 300),
        Cosmetic(id: "top-hat",    name: "Top Hat",      slot: .hat,  kind: .topHat,       rarity: .rare,   cost: 300),
        Cosmetic(id: "beret",      name: "Beret",        slot: .hat,  kind: .beret,        rarity: .common, cost: 120),
        Cosmetic(id: "bow-head",   name: "Head Bow",     slot: .hat,  kind: .bowOnHead,    rarity: .common, cost: 120),
        // batch 2a hats
        Cosmetic(id: "bobble-hat", name: "Bobble Hat",   slot: .hat,  kind: .bobbleHat,    rarity: .common, cost: 120),
        Cosmetic(id: "earflap-hat", name: "Earflap Hat", slot: .hat,  kind: .earflapHat,   rarity: .rare,   cost: 250),
        Cosmetic(id: "leaf-hat",   name: "Leaf",         slot: .hat,  kind: .leafHat,      rarity: .common, cost: 120),
        Cosmetic(id: "flower-hat", name: "Daisy",        slot: .hat,  kind: .singleFlower, rarity: .common, cost: 120),
        Cosmetic(id: "snow-hat",   name: "Snow",         slot: .hat,  kind: .snowHat,      rarity: .common, cost: 120),
        Cosmetic(id: "fried-egg",  name: "Fried Egg",    slot: .hat,  kind: .friedEggHat,  rarity: .rare,   cost: 250),
        Cosmetic(id: "pumpkin-hat", name: "Pumpkin",     slot: .hat,  kind: .pumpkinHat,   rarity: .rare,   cost: 280),
        Cosmetic(id: "acorn-hat",  name: "Acorn",        slot: .hat,  kind: .acornCap,     rarity: .rare,   cost: 250),
        Cosmetic(id: "bucket-hat", name: "Bucket Hat",   slot: .hat,  kind: .bucketHat,    rarity: .common, cost: 120),
        // batch 2b hats
        Cosmetic(id: "cupcake-hat", name: "Cupcake",     slot: .hat,  kind: .cupcakeHat,   rarity: .epic,   cost: 460),
        Cosmetic(id: "wizard-hat", name: "Wizard Hat",   slot: .hat,  kind: .wizardHat,    rarity: .epic,   cost: 480),
        Cosmetic(id: "chef-hat",   name: "Chef Hat",     slot: .hat,  kind: .chefHat,      rarity: .rare,   cost: 250),
        Cosmetic(id: "cowboy-hat", name: "Cowboy Hat",   slot: .hat,  kind: .cowboyHat,    rarity: .rare,   cost: 300),
        Cosmetic(id: "headphones", name: "Headphones",   slot: .hat,  kind: .headphones,   rarity: .rare,   cost: 280),
        Cosmetic(id: "tiara",      name: "Tiara",        slot: .hat,  kind: .tiara,        rarity: .epic,   cost: 460),
        Cosmetic(id: "little-horns", name: "Little Horns", slot: .hat, kind: .littleHorns, rarity: .rare,   cost: 280),
        Cosmetic(id: "soft-halo",  name: "Halo",         slot: .hat,  kind: .softHalo,     rarity: .epic,   cost: 500),
        Cosmetic(id: "propeller",  name: "Propeller Cap", slot: .hat, kind: .propellerCap, rarity: .rare,   cost: 280),
        // eyes
        Cosmetic(id: "glasses",    name: "Glasses",      slot: .eyes, kind: .roundGlasses, rarity: .common, cost: 0),
        Cosmetic(id: "sunglasses", name: "Sunnies",      slot: .eyes, kind: .sunglasses,   rarity: .common, cost: 120),
        Cosmetic(id: "star-shades",name: "Star Shades",  slot: .eyes, kind: .starShades,   rarity: .epic,   cost: 500),
        // eyes (docs/cosmetics/eyes.md)
        Cosmetic(id: "round-specs", name: "Round Specs", slot: .eyes, kind: .roundReadingGlasses, rarity: .common, cost: 120),
        Cosmetic(id: "square-frames", name: "Square Frames", slot: .eyes, kind: .squareGlasses, rarity: .common, cost: 120),
        Cosmetic(id: "cat-eye",    name: "Cat-Eye",      slot: .eyes, kind: .catEyeGlasses, rarity: .rare,  cost: 280),
        Cosmetic(id: "half-moon",  name: "Half-Moon",    slot: .eyes, kind: .halfMoonGlasses, rarity: .rare, cost: 250),
        Cosmetic(id: "heart-glasses", name: "Heart Glasses", slot: .eyes, kind: .heartGlasses, rarity: .rare, cost: 280),
        Cosmetic(id: "aviators",   name: "Aviators",     slot: .eyes, kind: .aviatorSunglasses, rarity: .rare, cost: 280),
        Cosmetic(id: "round-sunnies", name: "Round Sunnies", slot: .eyes, kind: .roundSunglasses, rarity: .common, cost: 120),
        Cosmetic(id: "visor",      name: "Visor Shades", slot: .eyes, kind: .visorShades,  rarity: .epic,   cost: 450),
        Cosmetic(id: "monocle",    name: "Monocle",      slot: .eyes, kind: .monocle,      rarity: .epic,   cost: 450),
        Cosmetic(id: "3d-glasses", name: "3D Glasses",   slot: .eyes, kind: .threeDGlasses, rarity: .rare,  cost: 250),
        Cosmetic(id: "swim-goggles", name: "Swim Goggles", slot: .eyes, kind: .swimGoggles, rarity: .rare, cost: 250),
        Cosmetic(id: "sleep-mask", name: "Sleep Mask",   slot: .eyes, kind: .sleepMask,    rarity: .common, cost: 120),
        Cosmetic(id: "hero-mask",  name: "Hero Mask",    slot: .eyes, kind: .dominoMask,   rarity: .epic,   cost: 450),
        Cosmetic(id: "eyepatch",   name: "Eyepatch",     slot: .eyes, kind: .eyepatch,     rarity: .common, cost: 120),
        Cosmetic(id: "sparkle-eyes", name: "Sparkle Eyes", slot: .eyes, kind: .sparkleEyes, rarity: .epic, cost: 500),
        Cosmetic(id: "bold-brows", name: "Bold Brows",   slot: .eyes, kind: .eyebrows,     rarity: .common, cost: 120),
        Cosmetic(id: "unibrow",    name: "Unibrow",      slot: .eyes, kind: .unibrow,      rarity: .rare,   cost: 250),
        Cosmetic(id: "googly",     name: "Googly Eyes",  slot: .eyes, kind: .googlyEyes,   rarity: .rare,   cost: 250),
        Cosmetic(id: "eye-bloom",  name: "Eye Bloom",    slot: .eyes, kind: .eyeFlower,    rarity: .rare,   cost: 280),
        Cosmetic(id: "freckles",   name: "Freckles",     slot: .eyes, kind: .freckles,     rarity: .common, cost: 0),
        Cosmetic(id: "face-gem",   name: "Face Gem",     slot: .eyes, kind: .faceGem,      rarity: .epic,   cost: 450),
        // neck
        Cosmetic(id: "bow",        name: "Bow",          slot: .neck, kind: .bow,          rarity: .common, cost: 0),
        Cosmetic(id: "bowtie",     name: "Bow Tie",      slot: .neck, kind: .bowtie,       rarity: .common, cost: 120),
        Cosmetic(id: "scarf",      name: "Scarf",        slot: .neck, kind: .scarf,        rarity: .rare,   cost: 250),
        // neck (docs/cosmetics/neck.md)
        Cosmetic(id: "knit-scarf", name: "Knit Scarf",   slot: .neck, kind: .knitScarf,    rarity: .common, cost: 120),
        Cosmetic(id: "striped-scarf", name: "Striped Scarf", slot: .neck, kind: .stripedScarf, rarity: .common, cost: 120),
        Cosmetic(id: "chunky-cowl", name: "Chunky Cowl", slot: .neck, kind: .chunkyCowl,   rarity: .rare,   cost: 260),
        Cosmetic(id: "infinity-scarf", name: "Infinity Scarf", slot: .neck, kind: .infinityScarf, rarity: .rare, cost: 280),
        Cosmetic(id: "dapper-bowtie", name: "Dapper Bow Tie", slot: .neck, kind: .dapperBowtie, rarity: .common, cost: 120),
        Cosmetic(id: "polka-bowtie", name: "Polka Bow Tie", slot: .neck, kind: .polkaBowtie, rarity: .common, cost: 120),
        Cosmetic(id: "necktie",    name: "Necktie",      slot: .neck, kind: .necktie,      rarity: .common, cost: 120),
        Cosmetic(id: "bandana",    name: "Bandana",      slot: .neck, kind: .bandana,      rarity: .common, cost: 120),
        Cosmetic(id: "bell-collar", name: "Bell Collar", slot: .neck, kind: .bellCollar,   rarity: .rare,   cost: 280),
        Cosmetic(id: "ruff-collar", name: "Ruff Collar", slot: .neck, kind: .ruffCollar,   rarity: .epic,   cost: 460),
        Cosmetic(id: "pearl-necklace", name: "Pearl Necklace", slot: .neck, kind: .pearlNecklace, rarity: .rare, cost: 270),
        Cosmetic(id: "pendant-necklace", name: "Heart Pendant", slot: .neck, kind: .pendantNecklace, rarity: .rare, cost: 290),
        Cosmetic(id: "star-pendant", name: "Star Pendant", slot: .neck, kind: .starPendant, rarity: .epic, cost: 470),
        Cosmetic(id: "flower-lei", name: "Flower Lei",   slot: .neck, kind: .flowerLei,    rarity: .epic,   cost: 480),
        Cosmetic(id: "cape",       name: "Cape",         slot: .neck, kind: .cape,         rarity: .epic,   cost: 480),
        Cosmetic(id: "medal-ribbon", name: "Medal",      slot: .neck, kind: .medalRibbon,  rarity: .rare,   cost: 300),
        Cosmetic(id: "locket",     name: "Locket",       slot: .neck, kind: .locket,       rarity: .rare,   cost: 290),
        Cosmetic(id: "baby-bib",   name: "Bib",          slot: .neck, kind: .babyBib,      rarity: .common, cost: 120),
        Cosmetic(id: "backpack-strap", name: "Backpack Strap", slot: .neck, kind: .backpackStrap, rarity: .rare, cost: 260),
        Cosmetic(id: "sash",       name: "Sash",         slot: .neck, kind: .sash,         rarity: .epic,   cost: 450),

        // --- spring bloom season (grant-only; you cannot buy these at any price) ---
        Cosmetic(id: "spring-blossom-crown", name: "Blossom Crown", slot: .hat,  kind: .blossomCrown,   rarity: .epic, cost: 0, grantOnly: true),
        Cosmetic(id: "spring-butterfly",     name: "Butterfly",     slot: .hat,  kind: .butterflyPerch, rarity: .epic, cost: 0, grantOnly: true),
        Cosmetic(id: "spring-watering-can",  name: "Watering Can",  slot: .hat,  kind: .wateringCan,    rarity: .rare, cost: 0, grantOnly: true),
        Cosmetic(id: "spring-petal-lashes",  name: "Petal Lashes",  slot: .eyes, kind: .petalLashes,    rarity: .rare, cost: 0, grantOnly: true),
        Cosmetic(id: "spring-rain-cape",     name: "Rain Cape",     slot: .neck, kind: .rainCape,       rarity: .epic, cost: 0, grantOnly: true),
        Cosmetic(id: "spring-clover-chain",  name: "Clover Chain",  slot: .neck, kind: .cloverChain,    rarity: .rare, cost: 0, grantOnly: true)
    ]

    static func items(in slot: CosmeticSlot) -> [Cosmetic] {
        all.filter { $0.slot == slot }
    }
}

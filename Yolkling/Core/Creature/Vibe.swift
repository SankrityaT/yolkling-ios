import SwiftUI

/// A creature's vibe: the IDENTITY of your yolkling, the part that stays the
/// same. Colour + base look (`style`). Later this expands into patterns,
/// freckles and accessory slots, so a small kit of parts makes millions of
/// unique creatures in code, no art team needed.
///
/// Identity is deliberately separate from emotion: a vibe never carries a mood.
/// How the creature *feels* right now lives in `YolkExpression` / `Mood`. The
/// user picks their colour and look directly at creation, then it grows more
/// uniquely theirs over time.
struct Vibe: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let body: Color
    let deep: Color
    let style: CreatureStyle
    /// A third colour used by some top features + patterns (stars, glows, rings).
    /// Defaults to `deep` when a species does not specify one.
    let accent: Color?
    /// A marking layered on the body. `.none` for the base vibes.
    let pattern: BodyPattern

    /// Limited-edition founding flair (aura, halo, iridescent body, crest,
    /// shimmer). `nil` for every normal creature.
    let flair: FoundingFlair?

    /// Premium body gradient stops for a bought colour "finish" (metallic sheen or
    /// iridescent duotone). `nil` for normal creatures, which use [body, body, deep].
    let bodyStops: [Color]?

    /// The colour features/patterns should use for their accent detail.
    var accentColor: Color { accent ?? deep }

    init(id: String, name: String, body: Color, deep: Color,
         style: CreatureStyle = .classic, accent: Color? = nil, pattern: BodyPattern = .none,
         flair: FoundingFlair? = nil, bodyStops: [Color]? = nil) {
        self.id = id
        self.name = name
        self.body = body
        self.deep = deep
        self.style = style
        self.accent = accent
        self.pattern = pattern
        self.flair = flair
        self.bodyStops = bodyStops
    }

    static let yolk   = Vibe(id: "yolk",   name: "yolk",   body: YolkColor.yolk,        deep: YolkColor.yolkDeep)
    static let ube    = Vibe(id: "ube",    name: "ube",    body: Color(hex: 0xB39BE8),  deep: Color(hex: 0x8466D6))
    static let matcha = Vibe(id: "matcha", name: "matcha", body: Color(hex: 0xB6D98C),  deep: Color(hex: 0x84B85E))
    static let bubble = Vibe(id: "bubble", name: "bubble", body: YolkColor.pink,        deep: Color(hex: 0xD86B9C))
    static let sky    = Vibe(id: "sky",    name: "sky",    body: YolkColor.sky,         deep: Color(hex: 0x5FA9E0))

    static let all: [Vibe] = [.yolk, .ube, .matcha, .bubble, .sky]
}

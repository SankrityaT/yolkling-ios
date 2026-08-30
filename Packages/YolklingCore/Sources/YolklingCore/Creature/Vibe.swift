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
public struct Vibe: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let body: Color
    public let deep: Color
    public let style: CreatureStyle
    /// A third colour used by some top features + patterns (stars, glows, rings).
    /// Defaults to `deep` when a species does not specify one.
    public let accent: Color?
    /// A marking layered on the body. `.none` for the base vibes.
    public let pattern: BodyPattern

    /// Limited-edition founding flair (aura, halo, iridescent body, crest,
    /// shimmer). `nil` for every normal creature.
    public let flair: FoundingFlair?

    /// Premium body gradient stops for a bought colour "finish" (metallic sheen or
    /// iridescent duotone). `nil` for normal creatures, which use [body, body, deep].
    public let bodyStops: [Color]?

    /// The colour features/patterns should use for their accent detail.
    public var accentColor: Color { accent ?? deep }

    public init(id: String, name: String, body: Color, deep: Color,
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

    public static let yolk   = Vibe(id: "yolk",   name: "yolk",   body: YolkColor.yolk,        deep: YolkColor.yolkDeep)
    public static let ube    = Vibe(id: "ube",    name: "ube",    body: Color(hex: 0xB39BE8),  deep: Color(hex: 0x8466D6))
    public static let matcha = Vibe(id: "matcha", name: "matcha", body: Color(hex: 0xB6D98C),  deep: Color(hex: 0x84B85E))
    public static let bubble = Vibe(id: "bubble", name: "bubble", body: YolkColor.pink,        deep: Color(hex: 0xD86B9C))
    public static let sky    = Vibe(id: "sky",    name: "sky",    body: YolkColor.sky,         deep: Color(hex: 0x5FA9E0))

    public static let all: [Vibe] = [.yolk, .ube, .matcha, .bubble, .sky]
}

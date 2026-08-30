import SwiftUI

/// A buyable "rare colour" for your yolk (the landing claim "rare colours"). Unlike
/// hats, a colour repaints the creature itself. Earned with Yolks only, never cash.
/// `deep` is derived from `body` (same rule as every player colour), so a swatch
/// only needs a body + optional accent and stays compatible with how Player stores
/// colour (colorHex + accentHex).
///
/// Premium swatches can carry a `finish` (a metallic sheen or an iridescent duotone)
/// so the rarest colours don't read as flat. The finish is derived purely from the
/// hexes, so it survives a relaunch even though only the hex is persisted (see
/// `bodyStops(forBody:)`), and it rides the body gradient that's already drawn.
public struct ColorSwatch: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let bodyHex: UInt
    public let accentHex: UInt?
    public let rarity: Rarity
    public let cost: Int
    public let finish: Finish

    public enum Finish: Sendable { case solid, gradient, sheen }

    public init(id: String, name: String, bodyHex: UInt, accentHex: UInt?, rarity: Rarity, cost: Int, finish: Finish = .solid) {
        self.id = id; self.name = name; self.bodyHex = bodyHex; self.accentHex = accentHex
        self.rarity = rarity; self.cost = cost; self.finish = finish
    }

    public var body: Color { Color(hex: bodyHex) }
    public var deep: Color { Color(hex: CreaturePalette.darker(bodyHex)) }
    public var accent: Color? { accentHex.map { Color(hex: $0) } }

    /// Premium body stops for the radial body gradient. `nil` = the default
    /// [body, body, deep]. `gradient` blends the lit edge toward the accent for an
    /// oil-slick read; `sheen` lifts the lit side for a metallic/gem glow.
    public var bodyStops: [Color]? {
        switch finish {
        case .solid:    return nil
        case .gradient: return [accent ?? body, body, deep]
        case .sheen:    return [Color(hex: CreaturePalette.lighter(bodyHex)), body, deep]
        }
    }

    /// Build a wearable vibe, preserving the creature's current look + pattern.
    public func vibe(style: CreatureStyle, pattern: BodyPattern) -> Vibe {
        Vibe(id: id, name: name, body: body, deep: deep, style: style,
             accent: accent, pattern: pattern, bodyStops: bodyStops)
    }
}

public enum ColorShop {
    public static let all: [ColorSwatch] = [
        // soft pastels (the gentle entry tier)
        ColorSwatch(id: "color-sunset",   name: "Sunset",    bodyHex: 0xFFB48A, accentHex: 0xFFD9A8, rarity: .rare, cost: 250),
        ColorSwatch(id: "color-lavender", name: "Lavender",  bodyHex: 0xC8B2E8, accentHex: 0xFFD7E2, rarity: .rare, cost: 250),
        ColorSwatch(id: "color-mint",     name: "Sea Glass", bodyHex: 0xA8E0C2, accentHex: 0xFFFFFF, rarity: .rare, cost: 250),
        ColorSwatch(id: "color-rose",     name: "Rose",      bodyHex: 0xF4A6B8, accentHex: 0xFFF0C2, rarity: .rare, cost: 280),

        // jewel + metal tier (deep, saturated, not pastel)
        ColorSwatch(id: "color-amethyst", name: "Amethyst",  bodyHex: 0x9B5FC0, accentHex: 0xE6C9FF, rarity: .rare, cost: 300),
        ColorSwatch(id: "color-emerald",  name: "Emerald",   bodyHex: 0x2FA877, accentHex: 0xBFF3D8, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-sapphire", name: "Sapphire",  bodyHex: 0x3E6FD6, accentHex: 0xBCD6FF, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-ruby",     name: "Ruby",      bodyHex: 0xD23B5E, accentHex: 0xFFC2CE, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-jade",     name: "Jade",      bodyHex: 0x4FB89A, accentHex: 0xDFF5EC, rarity: .rare, cost: 300),
        ColorSwatch(id: "color-garnet",   name: "Garnet",    bodyHex: 0xA23556, accentHex: 0xF0B6C4, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-teal",     name: "Deep Teal", bodyHex: 0x1F8A8C, accentHex: 0xACE7E6, rarity: .rare, cost: 300),
        ColorSwatch(id: "color-mulberry", name: "Mulberry",  bodyHex: 0x7E3F6E, accentHex: 0xE9C2DE, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-bronze",   name: "Bronze",    bodyHex: 0xB07A3C, accentHex: 0xF3D9A8, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-copper",   name: "Copper",    bodyHex: 0xC0703F, accentHex: 0xFAD0AE, rarity: .rare, cost: 320),
        ColorSwatch(id: "color-rosegold", name: "Rose Gold", bodyHex: 0xD68F86, accentHex: 0xFBE0D2, rarity: .rare, cost: 340),

        // epic standouts — with the metallic / iridescent finishes
        ColorSwatch(id: "color-moltengold", name: "Molten Gold", bodyHex: 0xE0A52E, accentHex: 0xFFE9A8, rarity: .epic, cost: 560, finish: .sheen),
        ColorSwatch(id: "color-obsidian",   name: "Obsidian",    bodyHex: 0x3A3550, accentHex: 0x8E86C4, rarity: .epic, cost: 620, finish: .sheen),
        ColorSwatch(id: "color-peacock",    name: "Peacock",     bodyHex: 0x1E7E8C, accentHex: 0x3FB6A6, rarity: .epic, cost: 600, finish: .gradient),
        ColorSwatch(id: "color-aurora",     name: "Aurora",      bodyHex: 0x4FB6A0, accentHex: 0xB9A0E6, rarity: .epic, cost: 680, finish: .gradient),
        ColorSwatch(id: "color-galaxy",     name: "Galaxy",      bodyHex: 0x4A3D7A, accentHex: 0x9AD8E6, rarity: .epic, cost: 700, finish: .gradient),
        ColorSwatch(id: "color-ember",      name: "Ember",       bodyHex: 0xC23B2E, accentHex: 0xFFB347, rarity: .epic, cost: 660, finish: .gradient),
    ]

    /// Resolve a premium finish from a stored body hex (the home creature is rebuilt
    /// from colorHex alone, not the swatch). nil for any non-premium hex.
    public static func bodyStops(forBody hex: UInt) -> [Color]? {
        all.first { $0.bodyHex == hex }?.bodyStops
    }
}

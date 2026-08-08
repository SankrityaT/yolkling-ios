import SwiftUI

/// Everything printed on one card.
///
/// A plain value with no stores and no environment in it, for two reasons. It has to
/// survive `ImageRenderer`, which draws outside the view hierarchy and gets neither. And a
/// card is a *record* — of a creature at a moment, with the numbers it had then — so
/// building it from live objects would quietly change old cards when the player changed.
struct YolkCardFace: Sendable {
    var name: String
    /// Species and family, e.g. "sunny yolkstar" / "celestial". Optional because a
    /// player's own custom creature belongs to no named species.
    var species: String?
    var family: String?
    var rarity: Species.Rarity
    var vibe: Vibe
    var expression: YolkExpression = .happy
    var outfit: [Cosmetic] = []
    /// The one-line flavour text. Species carry these already (`Species.personality`).
    var flavour: String?
    /// Up to four. More than four and the block stops reading as a glance.
    var stats: [Stat] = []
    /// Bottom-left, e.g. "no. 042 / 912".
    var serial: String?
    /// Bottom-right, e.g. "since aug 2026".
    var dateline: String?

    struct Stat: Sendable, Identifiable {
        var id: String { label }
        var label: String
        var value: String
        /// A small SF Symbol. Kept optional so a stat can be pure type when the icon
        /// would be noise.
        var icon: String?
    }

    /// The laminate. Rarity picks it, which is what makes rarity legible from across a
    /// room instead of being a word in the corner.
    var material: HoloMaterial { .forRarity(rarity) }
}

extension YolkCardFace {
    /// A species as a collectible card. This is the Dex entry.
    static func species(_ s: Species, discovered: Date? = nil, number: Int? = nil,
                        outOf: Int? = nil) -> YolkCardFace {
        var f = YolkCardFace(name: s.name, species: s.name, family: s.family,
                             rarity: s.rarity, vibe: s.vibe, expression: .happy)
        f.flavour = s.personality
        if let number, let outOf {
            f.serial = String(format: "no. %03d / %d", number, outOf)
        }
        if let discovered {
            f.dateline = "found " + discovered.formatted(.dateTime.month(.abbreviated).year())
                .lowercased()
        }
        return f
    }
}

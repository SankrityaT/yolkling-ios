import SwiftUI

/// Everything printed on one card.
///
/// A plain value with no stores and no environment in it, for two reasons. It has to
/// survive `ImageRenderer`, which draws outside the view hierarchy and gets neither. And a
/// card is a *record* — of a creature at a moment, with the numbers it had then — so
/// building it from live objects would quietly change old cards when the player changed.
struct YolkCardFace: Sendable {
    /// What kind of card this is. Drives the finish, the corner mark, and whether a
    /// serial number is printed. See ``Kind``.
    var kind: Kind = .species

    var name: String
    /// Species and family, e.g. "sunny yolkstar" / "celestial". Nil on a bond card,
    /// because the creature you made belongs to no named species.
    var species: String?
    var family: String?
    /// Only meaningful for `.species`. A bond card's finish comes from trust instead.
    var rarity: Species.Rarity
    var vibe: Vibe
    var expression: YolkExpression = .happy
    var outfit: [Cosmetic] = []
    /// The one-line flavour text. Species carry these already (`Species.personality`).
    var flavour: String?
    /// Up to four. More than four and the block stops reading as a glance.
    var stats: [Stat] = []
    /// Bottom-left, e.g. "no. 042 / 912". Nil on a bond card: yours is not one of a
    /// numbered run, it is the only one.
    var serial: String?
    /// Bottom-right, e.g. "since aug 2026".
    var dateline: String?

    /// Overrides the laminate. Set on bond cards, where the finish is earned from trust
    /// rather than picked by rarity.
    var finish: HoloMaterial?

    /// The three kinds of card, kept apart because the rules differ and collapsing them
    /// would let the wrong rule apply to the wrong card.
    enum Kind: Sendable {
        /// **Your creature.** One, forever. Never tradeable, giftable, duplicable or
        /// losable. Its finish is earned from trust and cannot be bought at any price.
        case bond
        /// A species you have met. A record of an encounter, with the species' own rarity.
        case species
        /// An item you own. This is the layer that trades.
        case cosmetic
    }

    struct Stat: Sendable, Identifiable {
        var id: String { label }
        var label: String
        var value: String
        /// A drawn glyph, not an SF Symbol. Kept optional so a stat can be pure type
        /// when the icon would be noise.
        var icon: YolkGlyph.Kind?
    }

    /// The laminate. Rarity picks it for a found species; trust picks it for the one you
    /// made. That split is the whole monetization argument in one property.
    var material: HoloMaterial { finish ?? .forRarity(rarity) }
}

extension YolkCardFace {
    /// A species as a collectible card. This is the Dex entry.
    static func species(_ s: Species, discovered: Date? = nil, number: Int? = nil,
                        outOf: Int? = nil) -> YolkCardFace {
        var f = YolkCardFace(kind: .species, name: s.name, species: s.name,
                             family: s.family, rarity: s.rarity, vibe: s.vibe,
                             expression: .happy)
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

    /// **Your yolkling.** The one card in the app that is not a collectible.
    ///
    /// No rarity, no serial, and a finish that comes from `trust` — which only rises when
    /// you look after yourself, and decays if you stop. So this card gets prettier the
    /// longer you have actually been showing up, and there is no way to pay for that.
    ///
    /// The stats are lifetime figures rather than current ones. `careStreak` would say how
    /// you are doing this week; `totalCareDays` says how long you have been here, and only
    /// the second one survives a bad fortnight without making the card feel like a
    /// reprimand.
    static func bond(name: String, vibe: Vibe, outfit: [Cosmetic] = [],
                     trust: Double, careDays: Int, focusMinutes: Int,
                     speciesFound: Int, createdAt: Date) -> YolkCardFace {
        var f = YolkCardFace(kind: .bond, name: name, species: nil, family: nil,
                             // `.common` is a placeholder that nothing reads: `finish`
                             // below overrides `material`, and a bond card prints no
                             // rarity chip. Rarity is a fact about a species, and yours
                             // isn't one.
                             rarity: .common, vibe: vibe, expression: .happy)
        f.outfit = outfit
        f.finish = .forTrust(trust)
        f.flavour = TrustStage.from(trust: trust).label
        f.stats = [
            .init(label: "days", value: "\(careDays)", icon: .cared),
            .init(label: "trust", value: "\(Int((trust * 100).rounded()))%", icon: .trust),
            .init(label: "focus", value: focusText(focusMinutes), icon: .focus),
            .init(label: "met", value: "\(speciesFound)", icon: .cards),
        ]
        f.dateline = "since " + createdAt.formatted(.dateTime.month(.abbreviated).year())
            .lowercased()
        return f
    }

    /// Minutes as something a card can print. Hours once there are any, because "1,284
    /// minutes" is a number you have to do arithmetic on before it means anything.
    private static func focusText(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = Double(minutes) / 60
        return hours < 10
            ? String(format: "%.1fh", hours)
            : "\(Int(hours.rounded()))h"
    }
}

import SwiftUI

/// The back of a card: dotted stock, and the yolkling mark pressed into it.
///
/// This exists so a card can be **face down**, which turns out to matter twice. It is the
/// first beat of the reveal ceremony (you see the back, then it cracks and flips), and it
/// is what an undiscovered species looks like in the collection — a card you have not
/// turned over yet, rather than a padlock.
///
/// **Common gets no dots.** Everything else gets the moiré. That is deliberate: the back
/// alone should tell you whether this one is worth flipping, which is exactly how a real
/// pack feels through the wrapper. If every back glowed, none of them would mean anything —
/// the same rule `RarityAura` follows for the same reason.
///
/// The mark is *engraved*, not printed: a highlight on one side and a shadow on the
/// opposite, both driven by tilt, so it reads as depth in the stock rather than ink on it.
/// Same trick as the name on the front, pushed harder because a whole shape can carry more
/// relief than a line of type before it starts looking like a bevel.
struct YolkCardBack: View {
    /// Picks the colourway and whether the dots appear at all. `nil` renders the plainest
    /// stock, for a card whose species you do not know yet.
    var rarity: Species.Rarity?
    var width: CGFloat = 300
    /// Where the card is pointing, in −1…1. Drives the engraving and the sheen.
    var pose: CGPoint = .zero

    private var height: CGFloat { width / YolkCard.aspect }
    private var u: CGFloat { width / 300 }

    /// No dots on a common. See the type comment.
    private var showsDots: Bool {
        guard let rarity else { return false }
        return rarity != .common
    }

    /// Two inks per rarity: the stock and the dots. Deliberately narrow-range — a card
    /// back is a texture, not a picture, and high contrast here fights the front.
    private var inks: (stock: Color, deep: Color, dot: Color) {
        switch rarity {
        case .common, .none:
            (Color(hex: 0xEFE6D4), Color(hex: 0xD8CBB2), Color(hex: 0xC9BA9C))
        case .rare:
            (Color(hex: 0xD8E4F2), Color(hex: 0xAFC4DE), Color(hex: 0x8FB0D4))
        case .epic:
            (Color(hex: 0xE8DCF2), Color(hex: 0xC4ACDE), Color(hex: 0xA98BD0))
        case .legendary:
            (Color(hex: 0xDCD8F0), Color(hex: 0xADA6D8), Color(hex: 0x8F86C8))
        case .founding:
            (Color(hex: 0xF6E7C4), Color(hex: 0xE0C48A), Color(hex: 0xCFAE6A))
        }
    }

    var body: some View {
        ZStack {
            stock
            if showsDots { dots }
            border
            engravedMark
            sheen
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18 * u, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18 * u, style: .continuous)
                .strokeBorder(YolkColor.ink.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: Layers

    private var stock: some View {
        let i = inks
        return ZStack {
            LinearGradient(colors: [i.stock, i.deep, i.stock],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            // A vignette, so the back has a centre for the mark to sit in.
            RadialGradient(colors: [.clear, i.deep.opacity(0.55)],
                           center: .center, startRadius: width * 0.2, endRadius: width * 1.0)
        }
    }

    /// The moiré. Two dot plates at slightly different pitches, one rotated a few degrees
    /// off the other.
    ///
    /// Off-angle on purpose. Perfectly aligned plates read as a single grid, and a grid
    /// reads as graph paper however fine you make it. Beating them against each other is
    /// what produces the shifting interference that makes this feel like printed foil
    /// stock. Same lesson the `prism` laminate taught the hard way.
    private var dots: some View {
        let i = inks
        return ZStack {
            DotPlate(pitch: 13 * u, radius: 1.7 * u)
                .foregroundStyle(i.dot.opacity(0.55))
            DotPlate(pitch: 15.5 * u, radius: 1.4 * u)
                .foregroundStyle(i.dot.opacity(0.34))
                .rotationEffect(.degrees(7))
                // Drifts with tilt, a fraction of the front's parallax. Enough that the
                // two plates come apart as you turn it; not enough to look detached.
                .offset(x: pose.x * 4 * u, y: pose.y * 3 * u)
        }
        .frame(width: width * 1.4, height: height * 1.4)
        .frame(width: width, height: height)   // collapse layout back, as the foil does
        .blendMode(.multiply)
    }

    /// An inset keyline, the way a real card back is trimmed.
    private var border: some View {
        RoundedRectangle(cornerRadius: 12 * u, style: .continuous)
            .strokeBorder(inks.dot.opacity(0.5), lineWidth: 1.5 * u)
            .padding(14 * u)
    }

    /// The yolkling mark, pressed into the stock.
    ///
    /// The relief comes from the two rim shadows, not from the fill. The fill is only a
    /// faint darkening, the way ink pools slightly in a depression — a solid shape would
    /// read as *printed*, which is the one thing this must not look like.
    ///
    /// **The offsets have a floor.** They are driven by tilt, but a card sitting near
    /// face-on has `pose` close to zero, and at zero a tilt-only emboss disappears
    /// completely: the highlight and shadow land exactly on top of each other and the mark
    /// vanishes. A fixed base offset keeps it pressed at rest and tilt only moves the light
    /// around, which is also what real relief does.
    private var engravedMark: some View {
        let base = 1.4 * u
        let dx = -pose.x * 2.2 * u + base
        let dy = -pose.y * 2.2 * u + base
        return YolkMark(width: width * 0.42)
            .foregroundStyle(inks.deep.opacity(0.38))
            .shadow(color: .white.opacity(0.95), radius: 0.5 * u, x: dx, y: dy)
            .shadow(color: YolkColor.ink.opacity(0.34), radius: 0.5 * u, x: -dx, y: -dy)
    }

    /// A broad soft highlight tracking the tilt, so the back catches light like a surface
    /// rather than sitting flat.
    private var sheen: some View {
        RadialGradient(colors: [.white.opacity(0.4), .clear],
                       center: UnitPoint(x: Holo.remap(pose.x, -1, 1, 0.1, 0.9),
                                         y: Holo.remap(pose.y, -1, 1, 0.1, 0.9)),
                       startRadius: 0, endRadius: width * 0.8)
            .blendMode(.softLight)
            .allowsHitTesting(false)
    }
}

// MARK: - Pieces

/// A grid of dots. Drawn in a `Canvas` rather than as a tiled image for the same reason
/// everything else here is: no assets, any resolution, and it costs arithmetic.
private struct DotPlate: View {
    let pitch: CGFloat
    let radius: CGFloat

    var body: some View {
        Canvas { ctx, size in
            guard pitch > 1 else { return }
            var y = pitch / 2
            var row = 0
            while y < size.height + pitch {
                // Offset alternate rows by half a pitch. A square lattice reads as a
                // screen door; a staggered one reads as halftone.
                let inset = row.isMultiple(of: 2) ? 0 : pitch / 2
                var x = pitch / 2 + inset
                while x < size.width + pitch {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius,
                                                    width: radius * 2, height: radius * 2)),
                             with: .style(.foreground))
                    x += pitch
                }
                y += pitch
                row += 1
            }
        }
    }
}

/// The yolkling mark: the creature reduced to its silhouette, which is the only part of it
/// that survives being pressed into card stock.
///
/// Not `YolklingView`. That draws a living creature with eyes, blush and a mouth, and an
/// engraving has no colour to spend on any of it — a debossed face at this size turns to
/// mud. A body, two feet and the little side nubs is what stays legible as relief, and it
/// is still unmistakably the same animal.
private struct YolkMark: View {
    let width: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let body = CGRect(x: w * 0.11, y: h * 0.06, width: w * 0.78, height: w * 0.78)
            ctx.fill(Path(ellipseIn: body), with: .style(.foreground))

            // Side nubs, at the body's vertical middle.
            let nub = CGSize(width: w * 0.13, height: w * 0.17)
            let nubY = body.midY - nub.height / 2
            ctx.fill(Path(ellipseIn: CGRect(x: body.minX - nub.width * 0.55, y: nubY,
                                            width: nub.width, height: nub.height)),
                     with: .style(.foreground))
            ctx.fill(Path(ellipseIn: CGRect(x: body.maxX - nub.width * 0.45, y: nubY,
                                            width: nub.width, height: nub.height)),
                     with: .style(.foreground))

            // Two feet, tucked under and slightly splayed.
            let foot = CGSize(width: w * 0.22, height: w * 0.12)
            let footY = body.maxY - foot.height * 0.45
            ctx.fill(Path(ellipseIn: CGRect(x: body.midX - foot.width * 1.15, y: footY,
                                            width: foot.width, height: foot.height)),
                     with: .style(.foreground))
            ctx.fill(Path(ellipseIn: CGRect(x: body.midX + foot.width * 0.15, y: footY,
                                            width: foot.width, height: foot.height)),
                     with: .style(.foreground))
        }
        .frame(width: width, height: width * 1.05)
    }
}

import SwiftUI

/// The app's own icons, drawn.
///
/// Everything else here is drawn in code — the creature, 203 species, the room, the card
/// laminates — and then the action row used **emoji**. A blue 🔁 sitting in a warm cream
/// interface is not a small inconsistency: it is a different palette, a different rendering
/// engine, and a different art direction, in the middle of the screen that is supposed to
/// prove the point. SF Symbols are better but they are still somebody else's line weight.
///
/// These are stroked rather than filled, matching the creature's own linework — the same
/// ink colour and roughly the same relative stroke width, so a glyph beside a yolkling
/// reads as having been drawn by the same hand.
///
/// Unit-square geometry scaled by `size`, so one definition is legible at 15pt in a button
/// and at 40pt in an empty state.
struct YolkGlyph: View {
    let kind: Kind
    var size: CGFloat = 17
    var weight: CGFloat = 0.085

    enum Kind: Sendable {
        /// Two arrows passing each other. A swap is two things moving in opposite
        /// directions, which is exactly what the shape should say.
        case swap
        /// A sealed envelope, for a postcard.
        case note
        /// A wrapped box.
        case gift
        /// Two overlapping cards, fanned. On-brand now that cards are the collection.
        case cards
        /// A raised hand.
        case wave
        /// A small yolk, for anything that means "your creature".
        case yolk
        /// A dashed path ending in a dot: went somewhere, came back.
        case wander
        /// Two yolks side by side.
        case friends
        /// Two arrows, one up one down.
        case sort
        /// A tick, for the chosen option in a list.
        case check
        /// A pennant, for reporting.
        case flag

        // MARK: Card stats
        //
        // The card is the surface most likely to end up in a screenshot, and it was the
        // last place still using SF Symbols — a flame, a heart, a raised palm and a
        // moon, all in Apple's line weight, sitting under hand-drawn linework. The palm
        // was the worst of them: `hand.raised.fill` is the universal "stop" gesture, so
        // the stat that counts the days somebody showed up for their creature was
        // labelled with a halt sign.

        /// A flame, for the care streak.
        case streak
        /// A heart, for trust.
        case trust
        /// A cupped hand with something held above it. Cradling, not halting.
        case cared
        /// A crescent and a spark, for focus minutes.
        case focus

        // MARK: Rarity marks
        //
        // One shape per rarity, escalating in how much they interrupt the eye: a plain
        // dot you skim past, a crown you cannot.

        /// A small filled dot. Common.
        case markDot
        /// A diamond. Rare.
        case markDiamond
        /// A five-pointed star. Epic.
        case markStar
        /// A four-point sparkle with two smaller ones. Legendary.
        case markSparkle
        /// A crown. Founding.
        case markCrown

        // MARK: Home
        //
        // The home screen was the last place still mixing three icon systems: literal
        // emoji in the streak pill, SF Symbols on the care cards and living stats, and
        // drawn glyphs everywhere else. Emoji are the worst of the three — they are a
        // different palette AND a different rendering engine, and they change shape with
        // the OS version, so the app's most-seen screen looked assembled rather than
        // drawn.

        /// A leaf. Rest tokens, which absorb a missed day.
        case leaf
        /// A walking figure. Steps.
        case steps
        /// A bed. Sleep. Deliberately not a crescent, which `focus` already uses.
        case sleep
        /// A phone. Time off it.
        case phone
        /// A house.
        case home
        /// A shopping bag.
        case shop
        /// A four-square grid. The collection.
        case grid
        /// A single person. Your profile.
        case person
        /// A heart with a pulse through it. Health, as distinct from `trust`.
        case health
        /// A padlock, for anything not unlocked yet.
        case lock
        /// A cross, for dismissing.
        case close
    }

    var body: some View {
        Canvas { ctx, box in
            let s = min(box.width, box.height)
            let w = s * weight
            let style = StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
            // `.foreground`, not a hardcoded ink. That makes the glyph tint from whatever
            // `foregroundStyle` it is placed in, so it works on a dark filled capsule
            // without the caller having to colour-multiply it back into visibility.
            let ink = GraphicsContext.Shading.style(.foreground)

            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            switch kind {
            case .swap:
                // Top arrow, pointing right.
                var top = Path()
                top.move(to: p(0.14, 0.34)); top.addLine(to: p(0.78, 0.34))
                top.move(to: p(0.62, 0.19)); top.addLine(to: p(0.80, 0.34))
                top.addLine(to: p(0.62, 0.49))
                ctx.stroke(top, with: ink, style: style)

                // Bottom arrow, pointing back. Offset rather than mirrored so the two do
                // not read as one double-headed arrow, which means something else.
                var bottom = Path()
                bottom.move(to: p(0.86, 0.68)); bottom.addLine(to: p(0.22, 0.68))
                bottom.move(to: p(0.38, 0.53)); bottom.addLine(to: p(0.20, 0.68))
                bottom.addLine(to: p(0.38, 0.83))
                ctx.stroke(bottom, with: ink, style: style)

            case .note:
                let body = CGRect(x: 0.10 * s, y: 0.24 * s, width: 0.80 * s, height: 0.52 * s)
                ctx.stroke(Path(roundedRect: body, cornerRadius: 0.08 * s), with: ink, style: style)
                var flap = Path()
                flap.move(to: p(0.13, 0.29)); flap.addLine(to: p(0.50, 0.55))
                flap.addLine(to: p(0.87, 0.29))
                ctx.stroke(flap, with: ink, style: style)

            case .gift:
                let box = CGRect(x: 0.15 * s, y: 0.42 * s, width: 0.70 * s, height: 0.44 * s)
                ctx.stroke(Path(roundedRect: box, cornerRadius: 0.06 * s), with: ink, style: style)
                let lid = CGRect(x: 0.10 * s, y: 0.30 * s, width: 0.80 * s, height: 0.14 * s)
                ctx.stroke(Path(roundedRect: lid, cornerRadius: 0.05 * s), with: ink, style: style)
                var ribbon = Path()
                ribbon.move(to: p(0.50, 0.30)); ribbon.addLine(to: p(0.50, 0.86))
                ctx.stroke(ribbon, with: ink, style: style)
                // Two loops for the bow, drawn as arcs rather than circles so they read as
                // ribbon rather than as ears.
                var bow = Path()
                bow.move(to: p(0.50, 0.29))
                bow.addQuadCurve(to: p(0.50, 0.29), control: p(0.16, 0.02))
                bow.move(to: p(0.50, 0.29))
                bow.addQuadCurve(to: p(0.50, 0.29), control: p(0.84, 0.02))
                ctx.stroke(bow, with: ink, style: style)

            case .cards:
                // Back card, tilted away.
                var back = Path(roundedRect: CGRect(x: 0.18 * s, y: 0.20 * s,
                                                    width: 0.42 * s, height: 0.58 * s),
                                cornerRadius: 0.06 * s)
                back = back.applying(.init(translationX: 0.38 * s, y: 0.49 * s)
                    .rotated(by: -0.22)
                    .translatedBy(x: -0.38 * s, y: -0.49 * s))
                ctx.stroke(back, with: ink, style: style)

                // Front card, upright and offset. Filled with the shell so the back card's
                // edge does not read through it, which at this size turns to mush.
                let front = Path(roundedRect: CGRect(x: 0.40 * s, y: 0.24 * s,
                                                     width: 0.42 * s, height: 0.58 * s),
                                 cornerRadius: 0.06 * s)
                ctx.fill(front, with: .color(YolkColor.shell2))
                ctx.stroke(front, with: ink, style: style)

            case .wave:
                // A hand, and it has to survive being 16pt across.
                //
                // The first version had four fingers 0.09 wide, a thumb, and two motion
                // arcs. At the stroke weight everything else uses, a 0.09 finger is almost
                // entirely stroke — the interiors filled in and the whole thing rendered as
                // a dark blob with a stray tick beside it. Zoomed screenshot made that
                // obvious and nothing else would have.
                //
                // So: three fingers, each WIDER than the stroke by a clear margin, real
                // gaps between them, no thumb, and no motion arcs. Fewer marks that each
                // survive is worth more than an anatomically complete hand that does not.
                var hand = Path()
                hand.addRoundedRect(in: CGRect(x: 0.26 * s, y: 0.48 * s,
                                               width: 0.56 * s, height: 0.34 * s),
                                    cornerSize: CGSize(width: 0.12 * s, height: 0.12 * s))
                for i in 0..<3 {
                    let x = 0.28 + CGFloat(i) * 0.19
                    hand.addRoundedRect(in: CGRect(x: x * s, y: 0.20 * s,
                                                   width: 0.15 * s, height: 0.34 * s),
                                        cornerSize: CGSize(width: 0.075 * s, height: 0.075 * s))
                }
                // A slight tilt so it reads as raised rather than as a diagram of a hand.
                let tilted = hand.applying(.init(translationX: 0.54 * s, y: 0.6 * s)
                    .rotated(by: 0.16)
                    .translatedBy(x: -0.54 * s, y: -0.6 * s))
                ctx.stroke(tilted, with: ink, style: style)

            case .wander:
                // A dashed path with a dot at the end. Dashed rather than solid because
                // the point is that you did not see the journey, only that it happened.
                var path = Path()
                path.move(to: p(0.12, 0.74))
                path.addCurve(to: p(0.70, 0.30),
                              control1: p(0.30, 0.86), control2: p(0.44, 0.20))
                ctx.stroke(path, with: ink,
                           style: StrokeStyle(lineWidth: w, lineCap: .round,
                                              dash: [0.055 * s, 0.075 * s]))
                ctx.fill(Path(ellipseIn: CGRect(x: 0.68 * s, y: 0.20 * s,
                                                width: 0.19 * s, height: 0.19 * s)),
                         with: ink)

            case .friends:
                // Two yolks side by side, NOT overlapping.
                //
                // The previous version overlapped them and punched the near one out by
                // filling it with `YolkColor.shell`. That only works on a shell
                // background — on the care card (shell2) and in the tab bar the fill did
                // not match what was behind it, so the pair read as two interlocking
                // rings rather than as two creatures. Separating them removes the need to
                // know the background at all, and the feet do the work of saying
                // "creature" that a bare circle cannot.
                let far = CGRect(x: 0.52 * s, y: 0.20 * s, width: 0.34 * s, height: 0.34 * s)
                ctx.stroke(Path(ellipseIn: far), with: ink, style: style)
                var farFeet = Path()
                farFeet.addEllipse(in: CGRect(x: 0.57 * s, y: 0.55 * s, width: 0.09 * s, height: 0.06 * s))
                farFeet.addEllipse(in: CGRect(x: 0.72 * s, y: 0.55 * s, width: 0.09 * s, height: 0.06 * s))
                ctx.stroke(farFeet, with: ink, style: style)

                let near = CGRect(x: 0.10 * s, y: 0.32 * s, width: 0.40 * s, height: 0.40 * s)
                ctx.stroke(Path(ellipseIn: near), with: ink, style: style)
                var nearFeet = Path()
                nearFeet.addEllipse(in: CGRect(x: 0.16 * s, y: 0.73 * s, width: 0.10 * s, height: 0.07 * s))
                nearFeet.addEllipse(in: CGRect(x: 0.33 * s, y: 0.73 * s, width: 0.10 * s, height: 0.07 * s))
                ctx.stroke(nearFeet, with: ink, style: style)

            case .sort:
                var up = Path()
                up.move(to: p(0.32, 0.82)); up.addLine(to: p(0.32, 0.20))
                up.move(to: p(0.19, 0.34)); up.addLine(to: p(0.32, 0.18))
                up.addLine(to: p(0.45, 0.34))
                ctx.stroke(up, with: ink, style: style)
                var down = Path()
                down.move(to: p(0.68, 0.18)); down.addLine(to: p(0.68, 0.80))
                down.move(to: p(0.55, 0.66)); down.addLine(to: p(0.68, 0.82))
                down.addLine(to: p(0.81, 0.66))
                ctx.stroke(down, with: ink, style: style)

            case .check:
                var tick = Path()
                tick.move(to: p(0.20, 0.52)); tick.addLine(to: p(0.42, 0.73))
                tick.addLine(to: p(0.80, 0.28))
                ctx.stroke(tick, with: ink, style: style)

            case .flag:
                var pole = Path()
                pole.move(to: p(0.26, 0.14)); pole.addLine(to: p(0.26, 0.88))
                ctx.stroke(pole, with: ink, style: style)
                var pennant = Path()
                pennant.move(to: p(0.26, 0.18))
                pennant.addLine(to: p(0.78, 0.32))
                pennant.addLine(to: p(0.26, 0.48))
                pennant.closeSubpath()
                ctx.stroke(pennant, with: ink, style: style)

            case .yolk:
                ctx.stroke(Path(ellipseIn: CGRect(x: 0.18 * s, y: 0.16 * s,
                                                  width: 0.64 * s, height: 0.64 * s)),
                           with: ink, style: style)
                var feet = Path()
                feet.addEllipse(in: CGRect(x: 0.30 * s, y: 0.74 * s, width: 0.17 * s, height: 0.11 * s))
                feet.addEllipse(in: CGRect(x: 0.53 * s, y: 0.74 * s, width: 0.17 * s, height: 0.11 * s))
                ctx.stroke(feet, with: ink, style: style)

            // MARK: Card stats

            case .streak:
                // Asymmetric on purpose. A symmetric teardrop is a water drop, which is
                // exactly what the first version of this rendered as — the shoulder on
                // the left and the lean on the tip are the whole difference between
                // "flame" and "raindrop" at 10pt.
                var flame = Path()
                flame.move(to: p(0.62, 0.05))
                flame.addQuadCurve(to: p(0.83, 0.55), control: p(0.76, 0.26))
                flame.addQuadCurve(to: p(0.50, 0.93), control: p(0.87, 0.83))
                flame.addQuadCurve(to: p(0.17, 0.55), control: p(0.13, 0.83))
                flame.addQuadCurve(to: p(0.41, 0.29), control: p(0.21, 0.37))
                // The concave notch back up into the tip. This is the one segment that
                // distinguishes a flame from a raindrop, so it is drawn hard rather than
                // subtly — a gentle version of it disappears entirely at 10pt, which is
                // what the previous two attempts got wrong.
                flame.addQuadCurve(to: p(0.62, 0.05), control: p(0.38, 0.13))
                ctx.stroke(flame, with: ink, style: style)

            case .trust:
                var heart = Path()
                heart.move(to: p(0.50, 0.86))
                heart.addCurve(to: p(0.10, 0.40), control1: p(0.20, 0.66), control2: p(0.10, 0.54))
                heart.addCurve(to: p(0.50, 0.34), control1: p(0.10, 0.20), control2: p(0.40, 0.18))
                heart.addCurve(to: p(0.90, 0.40), control1: p(0.60, 0.18), control2: p(0.90, 0.20))
                heart.addCurve(to: p(0.50, 0.86), control1: p(0.90, 0.54), control2: p(0.80, 0.66))
                ctx.stroke(heart, with: ink, style: style)

            case .cared:
                // A sprout, not a pair of hands.
                //
                // The hands version put a bowl under two upward ticks with a dot between
                // them, and at 10pt that is a face: the ticks became eyes and the bowl
                // became a smile. A sprout has no such collision, it is legible small,
                // and "days I showed up" reading as growth is the app's own thesis.
                var stem = Path()
                stem.move(to: p(0.50, 0.90))
                stem.addQuadCurve(to: p(0.50, 0.42), control: p(0.46, 0.66))
                ctx.stroke(stem, with: ink, style: style)

                var leaves = Path()
                // Right leaf.
                leaves.move(to: p(0.50, 0.54))
                leaves.addQuadCurve(to: p(0.86, 0.34), control: p(0.76, 0.60))
                leaves.addQuadCurve(to: p(0.50, 0.54), control: p(0.72, 0.32))
                // Left leaf, smaller and higher, so the pair is not a mirrored butterfly.
                leaves.move(to: p(0.50, 0.44))
                leaves.addQuadCurve(to: p(0.20, 0.26), control: p(0.28, 0.48))
                leaves.addQuadCurve(to: p(0.50, 0.44), control: p(0.26, 0.24))
                ctx.stroke(leaves, with: ink, style: style)

            case .focus:
                // A crescent, drawn as one arc so it stays a crescent at 9pt.
                var moon = Path()
                moon.move(to: p(0.66, 0.14))
                moon.addCurve(to: p(0.66, 0.86), control1: p(0.24, 0.26), control2: p(0.24, 0.74))
                ctx.stroke(moon, with: ink, style: style)
                var spark = Path()
                spark.move(to: p(0.80, 0.20)); spark.addLine(to: p(0.80, 0.40))
                spark.move(to: p(0.70, 0.30)); spark.addLine(to: p(0.90, 0.30))
                ctx.stroke(spark, with: ink, style: style)

            // MARK: Rarity marks
            //
            // Filled, not stroked. These sit inside a small capsule beside the rarity
            // word, where an outline at this size turns to mush.

            case .markDot:
                ctx.fill(Path(ellipseIn: CGRect(x: 0.28 * s, y: 0.28 * s,
                                                width: 0.44 * s, height: 0.44 * s)), with: ink)

            case .markDiamond:
                var d = Path()
                d.move(to: p(0.50, 0.10)); d.addLine(to: p(0.86, 0.50))
                d.addLine(to: p(0.50, 0.90)); d.addLine(to: p(0.14, 0.50))
                d.closeSubpath()
                ctx.fill(d, with: ink)

            case .markStar:
                var star = Path()
                for i in 0..<10 {
                    let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                    let r: CGFloat = i.isMultiple(of: 2) ? 0.44 : 0.18
                    let pt = CGPoint(x: (0.5 + cos(a) * r) * s, y: (0.5 + sin(a) * r) * s)
                    if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                }
                star.closeSubpath()
                ctx.fill(star, with: ink)

            case .markSparkle:
                // Concave sides, which is what separates a sparkle from a diamond.
                var sp = Path()
                sp.move(to: p(0.50, 0.04))
                sp.addQuadCurve(to: p(0.96, 0.50), control: p(0.58, 0.42))
                sp.addQuadCurve(to: p(0.50, 0.96), control: p(0.58, 0.58))
                sp.addQuadCurve(to: p(0.04, 0.50), control: p(0.42, 0.58))
                sp.addQuadCurve(to: p(0.50, 0.04), control: p(0.42, 0.42))
                ctx.fill(sp, with: ink)

            // MARK: Home

            case .leaf:
                var leaf = Path()
                leaf.move(to: p(0.20, 0.80))
                leaf.addQuadCurve(to: p(0.82, 0.20), control: p(0.28, 0.28))
                leaf.addQuadCurve(to: p(0.20, 0.80), control: p(0.74, 0.72))
                ctx.stroke(leaf, with: ink, style: style)
                var rib = Path()
                rib.move(to: p(0.24, 0.76)); rib.addLine(to: p(0.70, 0.32))
                ctx.stroke(rib, with: ink, style: style)

            case .steps:
                ctx.stroke(Path(ellipseIn: CGRect(x: 0.42 * s, y: 0.08 * s,
                                                  width: 0.19 * s, height: 0.19 * s)),
                           with: ink, style: style)
                var body = Path()
                body.move(to: p(0.52, 0.29)); body.addLine(to: p(0.46, 0.55))
                // Legs mid-stride, and an arm swinging opposite — a figure with both legs
                // together reads as standing, which is not what "steps" means.
                body.move(to: p(0.46, 0.55)); body.addLine(to: p(0.28, 0.86))
                body.move(to: p(0.46, 0.55)); body.addLine(to: p(0.70, 0.84))
                body.move(to: p(0.50, 0.38)); body.addLine(to: p(0.74, 0.46))
                ctx.stroke(body, with: ink, style: style)

            case .sleep:
                var bed = Path()
                bed.move(to: p(0.10, 0.34)); bed.addLine(to: p(0.10, 0.76))
                bed.move(to: p(0.10, 0.60)); bed.addLine(to: p(0.90, 0.60))
                bed.addLine(to: p(0.90, 0.76))
                ctx.stroke(bed, with: ink, style: style)
                var pillow = Path()
                pillow.move(to: p(0.24, 0.60))
                pillow.addQuadCurve(to: p(0.48, 0.60), control: p(0.36, 0.44))
                ctx.stroke(pillow, with: ink, style: style)

            case .phone:
                ctx.stroke(Path(roundedRect: CGRect(x: 0.28 * s, y: 0.10 * s,
                                                    width: 0.44 * s, height: 0.80 * s),
                                cornerRadius: 0.10 * s), with: ink, style: style)
                var speaker = Path()
                speaker.move(to: p(0.44, 0.21)); speaker.addLine(to: p(0.56, 0.21))
                ctx.stroke(speaker, with: ink, style: style)

            case .home:
                var roof = Path()
                roof.move(to: p(0.12, 0.48)); roof.addLine(to: p(0.50, 0.16))
                roof.addLine(to: p(0.88, 0.48))
                ctx.stroke(roof, with: ink, style: style)
                var walls = Path()
                walls.move(to: p(0.22, 0.44)); walls.addLine(to: p(0.22, 0.86))
                walls.addLine(to: p(0.78, 0.86)); walls.addLine(to: p(0.78, 0.44))
                ctx.stroke(walls, with: ink, style: style)

            case .shop:
                ctx.stroke(Path(roundedRect: CGRect(x: 0.18 * s, y: 0.36 * s,
                                                    width: 0.64 * s, height: 0.52 * s),
                                cornerRadius: 0.08 * s), with: ink, style: style)
                var handle = Path()
                handle.move(to: p(0.36, 0.40))
                handle.addQuadCurve(to: p(0.64, 0.40), control: p(0.50, 0.10))
                ctx.stroke(handle, with: ink, style: style)

            case .grid:
                for (gx, gy) in [(0.14, 0.14), (0.54, 0.14), (0.14, 0.54), (0.54, 0.54)] {
                    ctx.stroke(Path(roundedRect: CGRect(x: gx * s, y: gy * s,
                                                        width: 0.32 * s, height: 0.32 * s),
                                    cornerRadius: 0.07 * s), with: ink, style: style)
                }

            case .person:
                ctx.stroke(Path(ellipseIn: CGRect(x: 0.33 * s, y: 0.12 * s,
                                                  width: 0.34 * s, height: 0.34 * s)),
                           with: ink, style: style)
                var shoulders = Path()
                shoulders.move(to: p(0.16, 0.88))
                shoulders.addQuadCurve(to: p(0.84, 0.88), control: p(0.50, 0.50))
                ctx.stroke(shoulders, with: ink, style: style)

            case .health:
                var heart = Path()
                heart.move(to: p(0.50, 0.84))
                heart.addCurve(to: p(0.10, 0.42), control1: p(0.20, 0.66), control2: p(0.10, 0.54))
                heart.addCurve(to: p(0.50, 0.36), control1: p(0.10, 0.24), control2: p(0.40, 0.22))
                heart.addCurve(to: p(0.90, 0.42), control1: p(0.60, 0.22), control2: p(0.90, 0.24))
                heart.addCurve(to: p(0.50, 0.84), control1: p(0.90, 0.54), control2: p(0.80, 0.66))
                ctx.stroke(heart, with: ink, style: style)
                // The pulse is what separates this from `trust`, so it crosses the whole
                // shape rather than sitting inside it.
                var pulse = Path()
                pulse.move(to: p(0.06, 0.56)); pulse.addLine(to: p(0.32, 0.56))
                pulse.addLine(to: p(0.41, 0.42)); pulse.addLine(to: p(0.53, 0.68))
                pulse.addLine(to: p(0.62, 0.56)); pulse.addLine(to: p(0.94, 0.56))
                ctx.stroke(pulse, with: ink, style: style)

            case .lock:
                ctx.stroke(Path(roundedRect: CGRect(x: 0.22 * s, y: 0.44 * s,
                                                    width: 0.56 * s, height: 0.42 * s),
                                cornerRadius: 0.09 * s), with: ink, style: style)
                var shackle = Path()
                shackle.move(to: p(0.34, 0.44)); shackle.addLine(to: p(0.34, 0.30))
                shackle.addQuadCurve(to: p(0.66, 0.30), control: p(0.50, 0.08))
                shackle.addLine(to: p(0.66, 0.44))
                ctx.stroke(shackle, with: ink, style: style)

            case .close:
                var x = Path()
                x.move(to: p(0.22, 0.22)); x.addLine(to: p(0.78, 0.78))
                x.move(to: p(0.78, 0.22)); x.addLine(to: p(0.22, 0.78))
                ctx.stroke(x, with: ink, style: style)

            case .markCrown:
                var crown = Path()
                crown.move(to: p(0.12, 0.74))
                crown.addLine(to: p(0.12, 0.28))
                crown.addLine(to: p(0.31, 0.48))
                crown.addLine(to: p(0.50, 0.22))
                crown.addLine(to: p(0.69, 0.48))
                crown.addLine(to: p(0.88, 0.28))
                crown.addLine(to: p(0.88, 0.74))
                crown.closeSubpath()
                ctx.fill(crown, with: ink)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 18) {
        ForEach([YolkGlyph.Kind.swap, .note, .gift, .cards, .wave, .yolk], id: \.self) { k in
            YolkGlyph(kind: k, size: 34)
        }
    }
    .padding(30)
    .background(YolkColor.shell)
}

extension YolkGlyph.Kind: Hashable {}

import SwiftUI
import YolklingCore

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
                // Two yolks, the far one smaller and set back.
                ctx.stroke(Path(ellipseIn: CGRect(x: 0.46 * s, y: 0.20 * s,
                                                  width: 0.38 * s, height: 0.38 * s)),
                           with: ink, style: style)
                // Filled with the shell so the near one occludes the far one cleanly
                // rather than the two outlines crossing into a figure eight.
                let near = Path(ellipseIn: CGRect(x: 0.14 * s, y: 0.30 * s,
                                                  width: 0.46 * s, height: 0.46 * s))
                ctx.fill(near, with: .color(YolkColor.shell))
                ctx.stroke(near, with: ink, style: style)

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

import SwiftUI

/// The yolkling, rendered entirely in SwiftUI shapes. Identity comes from
/// `Vibe` (colour); emotion comes from a `YolkExpression` pose. The view tweens
/// smoothly between poses and layers a continuous "aliveness" loop (breath,
/// blink, bounce) on top, with amplitudes scaled by the pose's `energy`.
///
/// All motion is recomputed each frame from an eased interpolation, so there are
/// no animation conflicts and any mood change morphs cleanly. See
/// `docs/research/07-creature-expression.md`.
struct YolklingView: View {
    var vibe: Vibe = .yolk
    var expression: YolkExpression = .content
    var size: CGFloat = 220
    var outfit: [Cosmetic] = []
    /// Bump this to make the yolk wave hello (once it trusts you). A wave lasts ~1.7s.
    var waveToken: Int = 0
    /// Bump this to make the yolk celebrate (both arms up + a hop), ~1.2s.
    var celebrateToken: Int = 0
    /// Bump this when the user pets the yolk: anticipation, then a stretch that rings
    /// down, ~0.6s. Runs on the creature's own clock rather than an external
    /// `withAnimation`, so it can't fight the idle loop.
    var petToken: Int = 0
    /// When set, render ONE deterministic frame at this time (seconds on the creature's
    /// clock) instead of running the live loop.
    ///
    /// `ImageRenderer` renders outside the view hierarchy and cannot capture
    /// `TimelineView(.animation)`, so the share card, WidgetKit (which can't animate at
    /// all), snapshot tests, and Reduce Motion all render through this seam. The pose is
    /// taken straight from `expression` — no in-flight tween, no wave, no celebrate — so
    /// the same inputs always produce the same pixels.
    ///
    /// Use ``posedT`` unless you need a specific moment.
    var frozenAt: Double? = nil

    /// Draws the Yolkling Plus supporter glow. A plain Bool rather than a reach into
    /// `SubscriptionStore`, because this file compiles into the widget target and the
    /// store imports RevenueCat. Callers pass `subs.isPlus`; pass `false` for anyone
    /// else's creature, since we do not know a friend's subscription state and it is
    /// none of our business.
    var supporterGlow: Bool = false

    /// A good `frozenAt` for a still: mid-breath, and clear of the blink window
    /// (blinks occupy the first 0.16s of each 3.6s cycle, so eyes are open here).
    static let posedT: Double = 1.2

    // Pose transition state: we ease from `from` to `to` over `duration`.
    @State private var from: YolkExpression
    @State private var to: YolkExpression
    @State private var transitionStart = Date()
    @State private var epoch = Date()             // view-relative clock: small `t` = smooth, precise phases
    @State private var waveStartT: Double? = nil  // when the current wave began, on that clock
    @State private var celebrateStartT: Double? = nil
    @State private var petStartT: Double? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let duration: TimeInterval = 0.55

    init(vibe: Vibe = .yolk, expression: YolkExpression = .content, size: CGFloat = 220, outfit: [Cosmetic] = [], waveToken: Int = 0, celebrateToken: Int = 0, petToken: Int = 0, frozenAt: Double? = nil, supporterGlow: Bool = false) {
        self.vibe = vibe
        self.expression = expression
        self.size = size
        self.outfit = outfit
        self.waveToken = waveToken
        self.celebrateToken = celebrateToken
        self.petToken = petToken
        self.frozenAt = frozenAt
        self.supporterGlow = supporterGlow
        _from = State(initialValue: expression)
        _to = State(initialValue: expression)
    }

    var body: some View {
        Group {
            if let frozenAt {
                // One still frame. Pose comes from `expression` directly rather than the
                // `from`/`to` tween, which may never have settled in an offscreen render,
                // and one-shots are suppressed so a still is always the resting creature.
                creature(t: frozenAt, pose: expression,
                         waveStartT: nil, celebrateStartT: nil, petStartT: nil)
            } else {
                TimelineView(.animation) { ctx in
                    let now = ctx.date
                    creature(
                        t: now.timeIntervalSince(epoch),
                        pose: YolkExpression.lerp(from, to, smoothstep(progress(now))),
                        waveStartT: waveStartT,
                        celebrateStartT: celebrateStartT,
                        petStartT: petStartT
                    )
                }
            }
        }
        .frame(width: size * 1.4, height: size * 1.5)
        .onChange(of: expression) { _, newValue in
            let now = Date()
            from = YolkExpression.lerp(from, to, smoothstep(progress(now)))   // current visual pose
            to = newValue
            transitionStart = now
        }
        .onChange(of: waveToken) { _, _ in waveStartT = Date().timeIntervalSince(epoch) }
        .onChange(of: celebrateToken) { _, _ in celebrateStartT = Date().timeIntervalSince(epoch) }
        .onChange(of: petToken) { _, _ in petStartT = Date().timeIntervalSince(epoch) }
    }

    /// One frame of the creature, fully determined by `t` (seconds on the view-relative
    /// clock) and the already-resolved pose. Same inputs → same pixels, which is what
    /// makes `frozenAt`, the widget, and snapshot tests possible.
    private func creature(t: Double, pose: YolkExpression,
                          waveStartT: Double?, celebrateStartT: Double?, petStartT: Double?) -> some View {
        let motion = YolkMotion.at(t: t, bounce: pose.bounce,
                                   waveStartT: waveStartT, celebrateStartT: celebrateStartT,
                                   petStartT: petStartT, reduceMotion: reduceMotion)
        let e = pose
        let breath = motion.breath
        let celebrateAmt = motion.celebrate
        // Body travel normalised for the shadow: 0.10 of `size` reads as fully airborne,
        // so an idle breath barely moves it and a celebrate hop moves it a lot.
        let rise = min(1, motion.bodyRise / 0.10)

        // The body ZStack lifts by this much on breath and celebrate. The glow has to
        // borrow it, or the light stays pinned to the frame while the creature hops out
        // of it, which reads as two separate objects.
        let bodyLift = -size * 0.14 * e.bounce * (0.5 + 0.5 * breath) - size * 0.16 * celebrateAmt

        return ZStack {
            if let flair = vibe.flair {
                FoundingAura(flair: flair, size: size, t: t)
            }
            if supporterGlow {
                SupporterGlow(size: size, t: t, reduceMotion: reduceMotion)
                    .offset(y: bodyLift)
            }
            groundShadow(rise: rise)

            ZStack {
                if let flair = vibe.flair {
                    FoundingHalo(flair: flair, size: size)
                }
                // Everything that isn't the body trails it slightly and settles past it.
                // The body itself is the reference, so it gets no offset.
                arm(flip: false).offset(y: size * motion.trail(lag: YolkMotion.Lag.arm))
                arm(flip: true).offset(y: size * motion.trail(lag: YolkMotion.Lag.arm))
                foot(side: -1).offset(y: size * motion.trail(lag: YolkMotion.Lag.foot))
                foot(side: 1).offset(y: size * motion.trail(lag: YolkMotion.Lag.foot))
                topFeature().offset(y: size * motion.trail(lag: YolkMotion.Lag.hat))
                if let flair = vibe.flair {
                    FoundingCrest(flair: flair, size: size)
                        .offset(y: size * motion.trail(lag: YolkMotion.Lag.hat))
                }
                behindOutfitLayer(motion: motion)
                bodyCircle(e: e, breath: breath, blink: motion.blink, pet: motion.pet)
                outfitLayer(motion: motion)
                if motion.wave > 0.02 { wavingArm(amt: motion.wave, wig: motion.waveWiggle) }
                if celebrateAmt > 0.02 {
                    celebrateArm(side: -1, amt: celebrateAmt)
                    celebrateArm(side: 1, amt: celebrateAmt)
                }
            }
            .rotationEffect(.degrees(e.headTilt + e.bodyLean * 6), anchor: .bottom)
            .offset(y: bodyLift)

            ParticleLayer(particle: e.particle, t: t, size: size)
                // Same problem as the toppers, same fix. The sparkle particle is filled
                // with `YolkColor.yolk` and the hearts with `YolkColor.pink`, both fixed —
                // so an excited yellow creature threw yellow sparkles onto a yellow body,
                // and a pink one threw pink hearts onto pink. The particles drift partly
                // over the creature and partly over the background, so as with the
                // toppers only a dark halo separates them from both.
                // Two rims: a tight one that acts as an outline, and a wider soft one
                // that lifts the mark off whatever is behind it. A single subtle halo was
                // not enough — a yolk-yellow sparkle sitting on a yolk-yellow body has
                // essentially no luminance difference to work with, so the separation has
                // to come entirely from the rim.
                .shadow(color: YolkColor.ink.opacity(0.45), radius: size * 0.006)
                .shadow(color: YolkColor.ink.opacity(0.22), radius: size * 0.022)
                .offset(y: -size * 0.42)

            if let flair = vibe.flair {
                FoundingShimmer(flair: flair, size: size, t: t)
            }
        }
    }

    // MARK: Transition helpers

    private func progress(_ now: Date) -> Double {
        min(1, max(0, now.timeIntervalSince(transitionStart) / duration))
    }

    private func smoothstep(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    // MARK: Body

    private func bodyCircle(e: YolkExpression, breath: Double, blink: Double, pet: Double) -> some View {
        let amp = 0.02 + 0.03 * e.energy
        // The pet response rides on the same squash channel as the pose, so a pet during
        // an already-proud pose compounds rather than fighting it.
        let squash = e.squashStretch + 0.8 * pet
        let sx = (1 - 0.10 * squash) * (1 - 0.5 * amp * breath)
        let sy = (1 + 0.12 * squash) * (1 + amp * breath)
        return Circle()
            .fill(
                RadialGradient(
                    colors: vibe.flair?.bodyStops ?? vibe.bodyStops ?? [vibe.body, vibe.body, vibe.deep],
                    center: UnitPoint(x: 0.36, y: 0.30),
                    startRadius: size * 0.05,
                    endRadius: size * 0.72
                )
            )
            .frame(width: size, height: size)
            .overlay(
                BodyPatternView(pattern: vibe.pattern, bodyColor: vibe.body, deep: vibe.deep,
                                accent: vibe.accentColor, size: size)
                    .clipShape(Circle())
            )
            .overlay(face(e: e, blink: blink))
            .scaleEffect(x: sx, y: sy, anchor: .bottom)
            .shadow(color: vibe.deep.opacity(0.3), radius: size * 0.08, y: size * 0.05)
    }

    private func face(e: YolkExpression, blink: Double) -> some View {
        ZStack {
            blush(side: -1, e: e)
            blush(side: 1, e: e)
            brow(side: -1, e: e)
            brow(side: 1, e: e)
            eye(side: -1, e: e, blink: blink)
            eye(side: 1, e: e, blink: blink)
            mouth(e: e).offset(y: size * 0.14)
        }
    }

    // MARK: Brows

    /// `browAngle` has been a declared, lerped, preset-populated channel that drew
    /// nothing. Rendering it is what stops `low`, `tired`, `unwell` and `curious`
    /// reading as the same face.
    ///
    /// Every preset uses NEGATIVE values (−0.05 … −0.4), i.e. inner-end-up worry, so
    /// the multiplier is deliberately generous — at −0.4 this is a clear 16° tilt, at
    /// −0.05 it's a barely-there hint that fades in with opacity.
    @ViewBuilder
    private func brow(side: CGFloat, e: YolkExpression) -> some View {
        if abs(e.browAngle) > 0.03 {
            Capsule()
                .fill(YolkColor.ink)
                .frame(width: size * 0.13, height: size * 0.021)
                // Negative lifts the inner end (worry); positive drops it (scowl).
                .rotationEffect(.degrees(-Double(side) * e.browAngle * 40))
                .offset(x: side * size * 0.2, y: -size * 0.21)
                .opacity(min(1, abs(e.browAngle) * 3))
        }
    }

    // MARK: Eyes

    /// Every eye shape blinks, but each one differently: round eyes shorten, lid eyes
    /// flatten toward a line. Symbol eyes (heart/sparkle) deliberately don't — they read
    /// as an effect rather than an eyeball, and blinking them looks like a glitch.
    @ViewBuilder
    private func eye(side: CGFloat, e: YolkExpression, blink: Double) -> some View {
        // A wink closes ONE eye, so it is the only place the two sides diverge. `blink` is
        // OPENNESS (1 open, 0 shut), so a wink is just a lid that has come all the way down
        // on one side.
        //
        // `side > 0` is the creature's right, which is the one that winks. Arbitrary, but it
        // has to be consistent or the face swaps sides mid-transition.
        let lid = side > 0 ? min(blink, 1 - e.wink) : blink

        // A SHUT EYE IS A SHUT EYE, whatever the eye normally looks like.
        //
        // Folding the wink into `blink` and trusting each shape to handle it does not work:
        // `.heart` and `.sparkle` are drawn as symbols and ignore the lid entirely, so a
        // fully winking heart eye rendered as a wide-open heart. Screenshot showed two
        // hearts and no wink.
        //
        // Below this the shape stops mattering, because you cannot see a heart through a
        // closed eyelid. Threshold rather than a fade so the swap happens while the eye is
        // nearly shut and never reads as a pop.
        if lid < 0.28 {
            return AnyView(closedLid(openness: lid))
        }
        return AnyView(eyeBody(side: side, e: e, blink: lid))
    }

    /// A closed eye: the same soft arc a happy squint uses, flattened by how shut it is.
    /// One shape for blinks, winks and sleepy droops, so they all agree.
    private func closedLid(openness: Double) -> some View {
        LidEye(lift: max(0, openness / 0.28) * 0.5)
            .stroke(YolkColor.ink, style: StrokeStyle(lineWidth: size * 0.026, lineCap: .round))
            .frame(width: size * 0.2, height: size * 0.1)
    }

    private func eyeBody(side: CGFloat, e: YolkExpression, blink: Double) -> some View {
        Group {
            switch e.eyeShape {
            case .round:
                roundEye(e: e, blink: blink)
            case .happyArc:
                LidEye(lift: 1.0 * blink)
                    .stroke(YolkColor.ink, style: StrokeStyle(lineWidth: size * 0.026, lineCap: .round))
                    .frame(width: size * 0.2, height: size * 0.12)
            case .sleepy:
                LidEye(lift: 0.22 * blink)   // shallow, heavy-lidded droop, not a tall happy peak
                    .stroke(YolkColor.ink, style: StrokeStyle(lineWidth: size * 0.026, lineCap: .round))
                    .frame(width: size * 0.2, height: size * 0.1)
            case .heart:
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.17))
                    .foregroundStyle(YolkColor.pink)
            case .sparkle:
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.2))
                    .foregroundStyle(YolkColor.ink)
            }
        }
        .offset(x: side * size * 0.2, y: -size * 0.08)
    }

    private func roundEye(e: YolkExpression, blink: Double) -> some View {
        let openness = max(0.1, e.eyeOpenness * blink)
        return ZStack {
            Capsule()
                .fill(.white)
                .frame(width: size * 0.2, height: size * 0.23 * openness)
            Circle()
                .fill(YolkColor.ink)
                .frame(width: size * 0.1 * e.pupilScale, height: size * 0.1 * e.pupilScale)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.035, height: size * 0.035)
                        .offset(x: -size * 0.01, y: size * 0.012)
                        .opacity(e.catchlight)
                }
                .offset(x: e.pupilX * size * 0.045, y: -e.pupilY * size * 0.05)
                .opacity(openness > 0.18 ? 1 : 0)   // hide pupil when eye nearly shut
        }
    }

    // MARK: Cheeks

    private func blush(side: CGFloat, e: YolkExpression) -> some View {
        Ellipse()
            .fill(blushColor(e.blushHue))
            .frame(width: size * 0.15, height: size * 0.09)
            .blur(radius: 1)
            .opacity(e.blush)
            .offset(x: side * size * 0.31, y: size * 0.06)
    }

    private func blushColor(_ hue: YolkExpression.BlushHue) -> Color {
        switch hue {
        case .pink:  YolkColor.pink
        case .pale:  Color(hex: 0xE7C7CE)
        case .green: Color(hex: 0x9FD6A0)
        }
    }

    // MARK: Mouth

    private func mouth(e: YolkExpression) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: 0x6B3A4A))
                .frame(width: size * 0.15 * e.mouthWidth, height: size * 0.16 * e.mouthOpen)
                .opacity(e.mouthOpen > 0.02 ? 1 : 0)
            MouthLine(curve: e.mouthCurve, asymmetry: e.mouthAsymmetry)
                .stroke(YolkColor.ink, style: StrokeStyle(lineWidth: size * 0.024, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.2 * e.mouthWidth, height: size * 0.12)
        }
    }

    // MARK: Limbs + shadow

    private func arm(flip: Bool) -> some View {
        Capsule()
            .fill(vibe.body)
            .frame(width: size * 0.2, height: size * 0.12)
            .rotationEffect(.degrees(flip ? 18 : -18))
            .offset(x: (flip ? 1 : -1) * size * 0.46, y: size * 0.04)
    }

    /// A raised arm beside the head that waves hello, drawn in FRONT of the body so it
    /// reads clearly. `amt` (0..1) fades + grows it in; `wig` (-1..1) is the side wiggle.
    private func wavingArm(amt: Double, wig: Double) -> some View {
        Capsule()
            .fill(vibe.body)
            .frame(width: size * 0.15, height: size * 0.34)
            .rotationEffect(.degrees(-10 + wig * 26), anchor: .bottom)
            .offset(x: size * 0.4, y: -size * 0.18)
            .scaleEffect(min(1, amt * 1.4), anchor: .bottomLeading)
            .opacity(min(1, amt * 2.5))
    }

    /// One raised arm for a both-arms-up celebration, drawn in front, angled outward.
    private func celebrateArm(side: CGFloat, amt: Double) -> some View {
        Capsule()
            .fill(vibe.body)
            .frame(width: size * 0.15, height: size * 0.32)
            .rotationEffect(.degrees(Double(side) * 18), anchor: .bottom)
            .offset(x: side * size * 0.38, y: -size * 0.16)
            .scaleEffect(min(1, amt * 1.4), anchor: .bottom)
            .opacity(min(1, amt * 2.5))
    }

    private func foot(side: CGFloat) -> some View {
        Ellipse()
            .fill(vibe.deep)
            .frame(width: size * 0.2, height: size * 0.11)
            .offset(x: side * size * 0.2, y: size * 0.5)
    }

    // MARK: Worn cosmetics (the outfit layer), drawn in front at each slot anchor

    private func outfitLayer(motion: YolkMotion) -> some View {
        ForEach(outfit.filter { !$0.kind.rendersBehindBody }) { cosmetic in
            CosmeticView(kind: cosmetic.kind, size: size)
                .offset(y: cosmetic.slot.anchorY * size + size * motion.trail(lag: lag(for: cosmetic.slot)))
        }
    }

    /// Cosmetics that drape behind the body (capes), drawn before the body circle.
    private func behindOutfitLayer(motion: YolkMotion) -> some View {
        ForEach(outfit.filter { $0.kind.rendersBehindBody }) { cosmetic in
            CosmeticView(kind: cosmetic.kind, size: size)
                .offset(y: cosmetic.slot.anchorY * size + size * motion.trail(lag: lag(for: cosmetic.slot)))
        }
    }

    /// Per-slot trailing lag. Note this applies OUTSIDE `CosmeticView`, so all ~80
    /// cosmetics gain secondary motion without a single line changing in its 1,484-line
    /// switch — the renderer stays a dumb, pure function of `kind`.
    private func lag(for slot: CosmeticSlot) -> Double {
        switch slot {
        case .hat:  YolkMotion.Lag.hat
        case .neck: YolkMotion.Lag.neck
        case .eyes: YolkMotion.Lag.face
        }
    }

    // MARK: Base look (identity) — a top accent behind the head

    private func topFeature() -> some View {
        TopFeatureView(style: vibe.style, bodyColor: vibe.body, deep: vibe.deep,
                       accent: vibe.accentColor, size: size)
            // A tight dark halo so the topper's silhouette always reads.
            //
            // The toppers are what tell 58 looks apart, and most of them are filled with
            // `accent` — which resolves to `deep` when the creature has no explicit accent,
            // i.e. to a slightly darker version of the body. A darker-pink shape on a pink
            // body has almost nothing to separate it, and the ones with white highlights
            // vanish outright on a pale creature. The sprout only ever read clearly
            // because it happens to be green.
            //
            // Applied here, at the one call site, rather than as 58 individual colour
            // fixes: an occlusion edge separates the shape from whatever is behind it
            // without touching any of the art. It has to work against two very different
            // backdrops, because a topper peeking over the head is partly on the body and
            // partly on the cream background — which is exactly what a soft dark halo
            // does and what a lighter outline would not.
            .shadow(color: YolkColor.ink.opacity(0.28), radius: size * 0.011)
            .shadow(color: YolkColor.ink.opacity(0.16), radius: size * 0.03, y: size * 0.006)
    }

    /// The shadow reads weight: as the body rises it tightens, lightens and softens.
    /// Cheapest possible cue that the creature has mass and is leaving the ground —
    /// a shadow that stays put makes any bounce look like a sticker sliding around.
    private func groundShadow(rise: Double) -> some View {
        let r = min(1, max(0, rise))
        return Ellipse()
            .fill(YolkColor.ink.opacity(0.12 * (1 - 0.35 * r)))
            .frame(width: size * 0.66 * (1 - 0.25 * r), height: size * 0.1)
            .offset(y: size * 0.58)
            .blur(radius: 5 + r * 3)
    }
}

// MARK: - Mouth shape

/// The lip line. `curve` signed (-1 frown … +1 smile); `asymmetry` shifts the
/// control point sideways for a smirk. y grows downward, so a control point
/// below the corners reads as a smile.
private struct MouthLine: Shape {
    var curve: Double
    var asymmetry: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let depth = rect.height * curve * 1.2
        let cx = rect.midX + rect.width * 0.3 * asymmetry
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: cx, y: rect.midY + depth)
        )
        return p
    }
}

/// A closed-eye lid arc. `lift` controls the peak height: ~1.0 is the tall "^^"
/// happy eye, ~0.2 is a shallow, heavy-lidded drowsy eye.
private struct LidEye: Shape {
    var lift: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY - rect.height * (0.4 + 1.0 * lift))
        )
        return p
    }
}

// MARK: - Particles

/// A single dominant accent effect, driven by time `t` for gentle drift/twinkle.
private struct ParticleLayer: View {
    let particle: YolkExpression.Particle
    let t: Double
    let size: CGFloat

    var body: some View {
        switch particle {
        case .none:
            EmptyView()
        case .sparkles:
            ZStack {
                symbol("sparkle", at: CGPoint(x: 0.30, y: -0.02), scale: 0.13, twinkle: 0)
                symbol("sparkle", at: CGPoint(x: -0.28, y: 0.10), scale: 0.09, twinkle: 0.6)
                symbol("sparkle", at: CGPoint(x: 0.12, y: -0.14), scale: 0.07, twinkle: 1.2)
            }
            .foregroundStyle(YolkColor.yolk)
        case .hearts:
            ZStack {
                floater("heart.fill", lane: 0.22, scale: 0.10, phase: 0)
                floater("heart.fill", lane: -0.18, scale: 0.07, phase: 0.5)
            }
            .foregroundStyle(YolkColor.pink)
        case .zzz:
            ZStack {
                zee(index: 0)
                zee(index: 1)
                zee(index: 2)
            }
            .foregroundStyle(YolkColor.inkSoft)
        }
    }

    private func symbol(_ name: String, at p: CGPoint, scale: CGFloat, twinkle: Double) -> some View {
        let o = 0.4 + 0.6 * abs(sin(t * 2 + twinkle))
        return Image(systemName: name)
            .font(.system(size: size * scale))
            .opacity(o)
            .offset(x: p.x * size, y: p.y * size)
    }

    private func floater(_ name: String, lane: CGFloat, scale: CGFloat, phase: Double) -> some View {
        let cycle = (t * 0.5 + phase).truncatingRemainder(dividingBy: 1)
        return Image(systemName: name)
            .font(.system(size: size * scale))
            .opacity(1 - cycle)
            .offset(x: lane * size, y: -CGFloat(cycle) * size * 0.4)
    }

    private func zee(index: Int) -> some View {
        let cycle = (t * 0.4 + Double(index) * 0.33).truncatingRemainder(dividingBy: 1)
        return Text("z")
            .font(.system(size: size * (0.07 + 0.03 * CGFloat(index)), weight: .heavy, design: .rounded))
            .opacity(1 - cycle)
            .offset(x: size * (0.18 + 0.06 * CGFloat(index)), y: -CGFloat(cycle) * size * 0.3)
    }
}

#Preview("live") {
    VStack(spacing: 40) {
        YolklingView(vibe: .yolk, expression: .happy, size: 180)
        YolklingView(vibe: .bubble, expression: .sleepy, size: 180)
    }
    .padding(60)
    .background(YolkColor.shell)
}

/// The `frozenAt` seam: still frames, no live clock. These are what the share card
/// and the widget render, and what snapshot tests compare against — so if the two
/// previews ever disagree on pose, the seam has drifted.
#Preview("frozen") {
    VStack(spacing: 40) {
        YolklingView(vibe: .yolk, expression: .happy, size: 180, frozenAt: YolklingView.posedT)
        YolklingView(vibe: .bubble, expression: .sleepy, size: 180, frozenAt: YolklingView.posedT)
    }
    .padding(60)
    .background(YolkColor.shell)
}

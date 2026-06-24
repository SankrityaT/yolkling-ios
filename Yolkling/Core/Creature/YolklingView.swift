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

    // Pose transition state: we ease from `from` to `to` over `duration`.
    @State private var from: YolkExpression
    @State private var to: YolkExpression
    @State private var transitionStart = Date()
    @State private var epoch = Date()          // view-relative clock: small `t` = smooth, precise phases
    @State private var waveStart: Date? = nil  // when the current wave began
    @State private var celebrateStart: Date? = nil
    private let duration: TimeInterval = 0.55

    init(vibe: Vibe = .yolk, expression: YolkExpression = .content, size: CGFloat = 220, outfit: [Cosmetic] = [], waveToken: Int = 0, celebrateToken: Int = 0) {
        self.vibe = vibe
        self.expression = expression
        self.size = size
        self.outfit = outfit
        self.waveToken = waveToken
        self.celebrateToken = celebrateToken
        _from = State(initialValue: expression)
        _to = State(initialValue: expression)
    }

    var body: some View {
        TimelineView(.animation) { ctx in
            let now = ctx.date
            let pose = YolkExpression.lerp(from, to, smoothstep(progress(now)))
            let t = now.timeIntervalSince(epoch)
            // Constant breath frequency so a mood change never jumps the phase.
            // Energy/liveliness lives in amplitude + bounce (which interpolate smoothly).
            let breath = sin(2 * .pi * 0.3 * t)   // -1...1
            let e = blinking(pose, t: t)
            let waveAmt = waveAmount(now)
            let waveWig = waveWiggle(now)
            let celebrateAmt = celebrateAmount(now)

            ZStack {
                if let flair = vibe.flair {
                    FoundingAura(flair: flair, size: size, t: t)
                }
                groundShadow(e: e)

                ZStack {
                    if let flair = vibe.flair {
                        FoundingHalo(flair: flair, size: size)
                    }
                    arm(flip: false)
                    arm(flip: true)
                    foot(side: -1)
                    foot(side: 1)
                    topFeature()
                    if let flair = vibe.flair {
                        FoundingCrest(flair: flair, size: size)
                    }
                    behindOutfitLayer
                    bodyCircle(e: e, breath: breath)
                    outfitLayer
                    if waveAmt > 0.02 { wavingArm(amt: waveAmt, wig: waveWig) }
                    if celebrateAmt > 0.02 {
                        celebrateArm(side: -1, amt: celebrateAmt)
                        celebrateArm(side: 1, amt: celebrateAmt)
                    }
                }
                .rotationEffect(.degrees(e.headTilt + e.bodyLean * 6), anchor: .bottom)
                .offset(y: -size * 0.14 * e.bounce * (0.5 + 0.5 * breath) - size * 0.16 * celebrateAmt)

                ParticleLayer(particle: e.particle, t: t, size: size)
                    .offset(y: -size * 0.42)

                if let flair = vibe.flair {
                    FoundingShimmer(flair: flair, size: size, t: t)
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
        .onChange(of: waveToken) { _, _ in waveStart = Date() }
        .onChange(of: celebrateToken) { _, _ in celebrateStart = Date() }
    }

    // MARK: Transition helpers

    private func progress(_ now: Date) -> Double {
        min(1, max(0, now.timeIntervalSince(transitionStart) / duration))
    }

    private func smoothstep(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    /// Fold the idle blink into eye openness (round eyes only; arc/lid eyes are
    /// already closed and don't blink).
    private func blinking(_ pose: YolkExpression, t: Double) -> YolkExpression {
        guard pose.eyeShape == .round else { return pose }
        let cycle = 3.6                                        // constant: avoids phase jumps in blink timing
        let phase = t.truncatingRemainder(dividingBy: cycle)
        let window = 0.16
        let pulse = phase < window ? sin(.pi * phase / window) : 0     // 0 -> 1 -> 0
        var e = pose
        e.eyeOpenness *= (1 - 0.85 * pulse)
        return e
    }

    // MARK: Body

    private func bodyCircle(e: YolkExpression, breath: Double) -> some View {
        let amp = 0.02 + 0.03 * e.energy
        let sx = (1 - 0.10 * e.squashStretch) * (1 - 0.5 * amp * breath)
        let sy = (1 + 0.12 * e.squashStretch) * (1 + amp * breath)
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
            .overlay(face(e: e))
            .scaleEffect(x: sx, y: sy, anchor: .bottom)
            .shadow(color: vibe.deep.opacity(0.3), radius: size * 0.08, y: size * 0.05)
    }

    private func face(e: YolkExpression) -> some View {
        ZStack {
            blush(side: -1, e: e)
            blush(side: 1, e: e)
            eye(side: -1, e: e)
            eye(side: 1, e: e)
            mouth(e: e).offset(y: size * 0.14)
        }
    }

    // MARK: Eyes

    @ViewBuilder
    private func eye(side: CGFloat, e: YolkExpression) -> some View {
        Group {
            switch e.eyeShape {
            case .round:
                roundEye(e: e)
            case .happyArc:
                LidEye(lift: 1.0)
                    .stroke(YolkColor.ink, style: StrokeStyle(lineWidth: size * 0.026, lineCap: .round))
                    .frame(width: size * 0.2, height: size * 0.12)
            case .sleepy:
                LidEye(lift: 0.22)   // shallow, heavy-lidded droop, not a tall happy peak
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

    private func roundEye(e: YolkExpression) -> some View {
        let openness = max(0.1, e.eyeOpenness)
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

    /// The wave envelope (0 rest ... ~1 fully up) for `now`, ramping in and out over ~1.7s.
    private func waveAmount(_ now: Date) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.environment["YOLK_WAVE_FREEZE"] != nil { return 0.92 }
        #endif
        guard let ws = waveStart else { return 0 }
        let el = now.timeIntervalSince(ws)
        guard el >= 0, el <= 1.7 else { return 0 }
        let up = min(1, el / 0.22)
        let down = min(1, max(0, (1.7 - el) / 0.32))
        return up * down
    }

    /// The signed side-to-side wiggle (-1..1) of the wave for `now`.
    private func waveWiggle(_ now: Date) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.environment["YOLK_WAVE_FREEZE"] != nil { return 0.6 }
        #endif
        guard let ws = waveStart else { return 0 }
        let el = now.timeIntervalSince(ws)
        return sin(2 * .pi * 2.7 * el)
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

    /// The celebrate envelope (0 rest ... ~1 arms up + mid-hop) over ~1.2s.
    private func celebrateAmount(_ now: Date) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.environment["YOLK_CELEBRATE_FREEZE"] != nil { return 0.95 }
        #endif
        guard let cs = celebrateStart else { return 0 }
        let el = now.timeIntervalSince(cs)
        guard el >= 0, el <= 1.2 else { return 0 }
        let up = min(1, el / 0.18)
        let down = min(1, max(0, (1.2 - el) / 0.3))
        return up * down
    }

    private func foot(side: CGFloat) -> some View {
        Ellipse()
            .fill(vibe.deep)
            .frame(width: size * 0.2, height: size * 0.11)
            .offset(x: side * size * 0.2, y: size * 0.5)
    }

    // MARK: Worn cosmetics (the outfit layer), drawn in front at each slot anchor

    private var outfitLayer: some View {
        ForEach(outfit.filter { !$0.kind.rendersBehindBody }) { cosmetic in
            CosmeticView(kind: cosmetic.kind, size: size)
                .offset(y: cosmetic.slot.anchorY * size)
        }
    }

    /// Cosmetics that drape behind the body (capes), drawn before the body circle.
    private var behindOutfitLayer: some View {
        ForEach(outfit.filter { $0.kind.rendersBehindBody }) { cosmetic in
            CosmeticView(kind: cosmetic.kind, size: size)
                .offset(y: cosmetic.slot.anchorY * size)
        }
    }

    // MARK: Base look (identity) — a top accent behind the head

    private func topFeature() -> some View {
        TopFeatureView(style: vibe.style, bodyColor: vibe.body, deep: vibe.deep,
                       accent: vibe.accentColor, size: size)
    }

    private func groundShadow(e: YolkExpression) -> some View {
        Ellipse()
            .fill(YolkColor.ink.opacity(0.12))
            .frame(width: size * 0.66, height: size * 0.1)
            .offset(y: size * 0.58)
            .blur(radius: 5)
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

#Preview {
    VStack(spacing: 40) {
        YolklingView(vibe: .yolk, expression: .happy, size: 180)
        YolklingView(vibe: .bubble, expression: .sleepy, size: 180)
    }
    .padding(60)
    .background(YolkColor.shell)
}

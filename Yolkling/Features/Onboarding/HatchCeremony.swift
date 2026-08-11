import SwiftUI

/// The hatch.
///
/// The previous version never actually broke the egg: it squashed, then the creature
/// scaled in over the top while the egg crossfaded out. It read as a substitution rather
/// than as a birth, which is a shame — this is the one moment in the app that everybody
/// sees and it is the emotional payoff the whole creation flow is building toward.
///
/// This one cracks. A jagged fissure draws itself across the shell, the shell separates
/// into two pieces along exactly that line, the pieces fall away, and the creature comes
/// up through the gap.
///
/// **Why `KeyframeAnimator` rather than the chain of `Task.sleep` this replaces.** The old
/// choreography advanced one property at a time, so nothing could overlap: the squash had
/// to finish before the crack could start. Real motion overlaps — the shell is still
/// falling while the creature is already rising, and the glow peaks *during* the crack
/// rather than after it. Keyframes give each property its own independent timeline over
/// the same clock, which is the only way to express that. It is also scrubbable and
/// deterministic, so the same frame comes out every run.
struct HatchCeremony: View {
    let vibe: Vibe
    var size: CGFloat = 215
    /// Fires once, as the shell gives way, so the caller can land a haptic on the break
    /// rather than guessing at it.
    var onBreak: () -> Void = {}

    @State private var expression: YolkExpression = .surprised
    @State private var broke = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// When the ceremony started. Captured once, on appear.
    @State private var began: Date?

    var body: some View {
        ZStack {
            if reduceMotion {
                // No crack, no fall, no shake. Reduce Motion means the payoff still
                // happens — it just arrives rather than performs.
                stage(.settled)
            } else {
                TimelineView(.animation) { ctx in
                    stage(HatchPose.at(ctx.date.timeIntervalSince(began ?? ctx.date)))
                }
            }
        }
        .frame(width: size * 1.6, height: size * 1.6)
        .onAppear { if began == nil { began = .now } }
        .task { await sequence() }
    }

    // MARK: The composed frame

    @ViewBuilder
    private func stage(_ pose: HatchPose) -> some View {
        ZStack {
            glow(pose)
            // Drawn before the shell so the creature comes up from *behind* it, through
            // the gap the crack opens. Drawing it in front would put it on top of shell
            // pieces that are meant to be closer to camera than it is.
            creature(pose: pose)
            shell(pose)
        }
    }

    private func glow(_ pose: HatchPose) -> some View {
        Circle()
            .fill(vibe.body)
            .frame(width: size * 1.05, height: size * 1.05)
            .blur(radius: size * 0.22)
            .opacity(pose.glow * 0.55)
            .scaleEffect(0.8 + pose.glow * 0.35)
    }

    private func creature(pose: HatchPose) -> some View {
        YolklingView(vibe: vibe, expression: expression, size: size)
            // Scales from nearly nothing, and rises as it grows — a creature that only
            // scaled would look like a zoom rather than like something climbing out.
            .scaleEffect(pose.creature)
            .offset(y: size * 0.16 * (1 - pose.creature))
            .opacity(pose.creature > 0.02 ? 1 : 0)
    }

    /// The shell: one egg, masked into two pieces along the crack, plus the crack itself
    /// drawn as a stroke that trims on.
    private func shell(_ pose: HatchPose) -> some View {
        let w = size * 0.82
        let h = size

        return ZStack {
            // Upper piece — lifts, tips over and flies clear.
            eggBody
                .mask(CrackMask(below: false).frame(width: w, height: h))
                .frame(width: w, height: h)
                .rotationEffect(.degrees(-26 * pose.fall), anchor: .bottomTrailing)
                .offset(x: -size * 0.34 * pose.fall,
                        y: -size * 0.30 * pose.split - size * 0.10 * pose.fall)
                .opacity(pose.shellIn * (1 - pose.fall))

            // Lower piece — barely moves. The bottom of a real shell stays put and the
            // creature stands in it, so it drops only a little and fades late.
            eggBody
                .mask(CrackMask(below: true).frame(width: w, height: h))
                .frame(width: w, height: h)
                .rotationEffect(.degrees(9 * pose.fall), anchor: .bottomLeading)
                .offset(x: size * 0.16 * pose.fall,
                        y: size * 0.06 * pose.split + size * 0.16 * pose.fall)
                .opacity(pose.shellIn * (1 - pose.fall))

            // The fissure. Drawn over both pieces while they are still together, and gone
            // by the time they separate — once there is a real gap, a drawn line through
            // it would be a line floating in mid-air.
            CrackLine()
                .trim(from: 0, to: pose.crack)
                .stroke(YolkColor.ink.opacity(0.45),
                        style: StrokeStyle(lineWidth: max(1.5, size * 0.012),
                                           lineCap: .round, lineJoin: .round))
                .frame(width: w, height: h)
                .opacity(pose.shellIn * (1 - pose.split))
        }
        // Anticipation, applied to the shell as a whole: it rocks, then compresses just
        // before it gives.
        .scaleEffect(x: 1 + pose.squash * 0.14, y: 1 - pose.squash * 0.16, anchor: .bottom)
        .rotationEffect(.degrees(pose.shake * 3.2), anchor: .bottom)
    }

    private var eggBody: some View {
        EggShape()
            .fill(vibe.body)
            .overlay(
                RadialGradient(colors: [.white.opacity(0.55), .clear],
                               center: UnitPoint(x: 0.36, y: 0.28),
                               startRadius: size * 0.02, endRadius: size * 0.5)
            )
            .overlay(
                RadialGradient(colors: [.clear, .black.opacity(0.14)],
                               center: UnitPoint(x: 0.5, y: 0.66),
                               startRadius: size * 0.28, endRadius: size * 0.6)
            )
            .clipShape(EggShape())
    }

    // MARK: Side effects
    //
    // Deliberately NOT driven from the keyframe value. `content` runs every frame, and
    // firing a haptic or setting state from there would fire it sixty times a second.
    // These timings mirror `HatchPose.timeline` and must be kept in step with it.

    private func sequence() async {
        guard !reduceMotion else {
            expression = .happy
            onBreak()
            return
        }
        try? await Task.sleep(for: .seconds(HatchPose.breakAt))
        guard !broke else { return }
        broke = true
        onBreak()
        try? await Task.sleep(for: .seconds(0.75))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.66)) { expression = .happy }
    }
}

// MARK: - The animated value

/// Every property the hatch animates, each on its own track over one shared clock.
struct HatchPose {
    /// How much of the fissure has been drawn, 0...1.
    var crack: Double = 0
    /// Rocking, -1...1.
    var shake: Double = 0
    /// Anticipation compression, 0...1.
    var squash: Double = 0
    /// Shell halves parting, 0...1.
    var split: Double = 0
    /// Shell pieces tumbling away and fading, 0...1.
    var fall: Double = 0
    /// Creature scale, 0...1 (overshoots past 1 on the spring).
    var creature: Double = 0
    /// Light behind the shell, 0...1.
    var glow: Double = 0
    /// The shell closing over the creature at the start, 0...1.
    ///
    /// The previous screen now shows the creature, so the egg can no longer simply *be*
    /// there when this one opens — it would appear from nowhere and contradict what the
    /// player was just looking at. Instead the shell wraps around them: you make your
    /// yolkling, it tucks itself in, and then it breaks back out. That also gives the
    /// ceremony a beginning, which a straight cut to a waiting egg never had.
    var shellIn: Double = 0

    /// The frame the creature rests at, used for the Reduce Motion path.
    static let settled = HatchPose(crack: 1, split: 1, fall: 1, creature: 1, glow: 0, shellIn: 0)

    /// When the shell gives. Haptics and the expression change hang off this.
    static let breakAt: Double = 3.34

    /// The choreography, as a pure function of elapsed seconds.
    ///
    /// **Why this is not `KeyframeAnimator`.** It was, and the animator simply never
    /// advanced — the pose stayed at its initial value, every track at zero, so the whole
    /// ceremony rendered an empty screen. Rendering the same `stage()` with a hardcoded
    /// mid-ceremony pose drew perfectly, which isolated the fault to the animator rather
    /// than the drawing. Rather than keep guessing at it, this uses the motion
    /// architecture the rest of the app already runs on: a `TimelineView` clock and
    /// motion derived purely from `t` (see `YolkMotion`, `CardTilt`, the card laminates).
    ///
    /// That is the better answer anyway. It is deterministic, so a given second always
    /// produces the same frame and the ceremony is screenshot-verifiable; and the easing
    /// is written out in the open where it can be tuned, instead of being implied by a
    /// stack of keyframe durations.
    ///
    /// **Pacing.** The first pass ran the whole thing in 3.2s and read as frantic — the
    /// egg had barely settled before it was already breaking. This runs to ~4.9s, and
    /// more importantly it *eases in*: the first 0.8s is just the shell closing, then
    /// almost a full second of stillness before the rocking starts, and the rocking
    /// itself grows from nothing rather than arriving at full amplitude. Anticipation is
    /// most of what makes a payoff land, and anticipation is mostly waiting.
    static func at(_ t: Double) -> HatchPose {
        var p = HatchPose()

        // 1. The shell closes over the creature. Slow, and eased at both ends.
        p.shellIn = smooth(t, from: 0.10, to: 0.95)

        // 2. Light gathers. Starts long before anything happens, so by the time the egg
        //    moves it already feels like something is building.
        let gather = smooth(t, from: 1.15, to: 2.95)
        let flare  = smooth(t, from: 2.95, to: 3.25)
        let cool   = smooth(t, from: 3.35, to: 4.40)
        p.glow = min(1, gather * 0.55 + flare * 0.45) * (1 - cool * 0.95)

        // 3. Rocking, ramping in. The amplitude envelope is what eases here — the
        //    oscillation itself stays a constant frequency, because a rock that changes
        //    speed reads as a wobble in the animation rather than as effort.
        let rockIn  = smooth(t, from: 1.75, to: 2.75)
        let rockOut = 1 - smooth(t, from: 2.80, to: 3.00)
        p.shake = sin((t - 1.75) * 7.4) * rockIn * rockOut

        // 4. The held breath.
        let squashIn  = smooth(t, from: 2.80, to: 3.05)
        let squashOut = smooth(t, from: 3.18, to: 3.55)
        p.squash = squashIn * (1 - squashOut)

        // 5. The fissure. Quick — a slow crack looks like a zip being undone.
        p.crack = smooth(t, from: 3.06, to: 3.40)

        // 6. The shell gives.
        p.split = smooth(t, from: breakAt, to: breakAt + 0.42)
        p.fall  = smooth(t, from: breakAt + 0.20, to: breakAt + 1.30)

        // 7. The creature. Already on screen at the start (carried over from the previous
        //    step), hidden once the shell has closed, then pushing back out with a real
        //    overshoot.
        let hide = smooth(t, from: 0.55, to: 0.80)
        let rise = overshoot(smooth(t, from: breakAt - 0.10, to: breakAt + 0.95))
        p.creature = t < 0.80 ? (1 - hide) : rise

        return p
    }

    /// Smoothstep between two absolute times. Eased at BOTH ends, which is the whole
    /// point — a linear ramp starts and stops abruptly and that is most of what "too
    /// fast" actually means, even when the duration is unchanged.
    private static func smooth(_ t: Double, from a: Double, to b: Double) -> Double {
        guard b > a else { return t >= b ? 1 : 0 }
        let x = min(1, max(0, (t - a) / (b - a)))
        return x * x * (3 - 2 * x)
    }

    /// A 0...1 ramp that overshoots past 1 and settles back, so the creature arrives with
    /// weight instead of stopping dead on its final size.
    private static func overshoot(_ x: Double) -> Double {
        guard x > 0 else { return 0 }
        guard x < 1 else { return 1 }
        // Decaying sine on top of the ramp: one clear bounce, not a wobble.
        return x + sin(x * .pi) * 0.16 * (1 - x)
    }
}

// MARK: - Crack geometry
//
// The stroked crack and the two masks MUST agree exactly, or the shell will separate
// along a line that is not the one the player watched being drawn. So both are generated
// from `crackPoints(in:)` and neither owns the geometry.

/// The fissure, as a polyline across the egg.
///
/// Hand-tuned rather than randomised. A random zigzag gives every tooth the same
/// character; these vary in width and depth so the break has a direction — shallow at the
/// left, deepest just past centre, tailing off to the right, the way a shell actually
/// fails once a crack finds a weak point.
/// `nonisolated` because the project defaults to MainActor isolation and `Shape.path(in:)`
/// is not — the shapes below could not otherwise call this.
private nonisolated func crackPoints(in rect: CGRect) -> [CGPoint] {
    // x across the full width, y as a fraction of height. Slightly above centre, because
    // a lid taken off the top reads as hatching and a split down the middle reads as
    // breaking.
    let jag: [(CGFloat, CGFloat)] = [
        (-0.02, 0.470),
        (0.14, 0.436),
        (0.26, 0.494),
        (0.39, 0.430),
        (0.52, 0.512),
        (0.63, 0.442),
        (0.76, 0.492),
        (0.88, 0.452),
        (1.02, 0.478),
    ]
    return jag.map { CGPoint(x: rect.minX + rect.width * $0.0,
                             y: rect.minY + rect.height * $0.1) }
}

/// The crack, strokable and trimmable.
private struct CrackLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let pts = crackPoints(in: rect)
        p.move(to: pts[0])
        for pt in pts.dropFirst() { p.addLine(to: pt) }
        return p
    }
}

/// Everything above (or below) the crack, as a mask for the shell pieces.
///
/// Built by closing the polyline out to the far edge of the rect, well past the egg on
/// every side, so the mask covers the shell completely no matter how the egg is scaled
/// inside its frame.
private struct CrackMask: Shape {
    /// true = keep the region below the crack.
    let below: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let pts = crackPoints(in: rect)
        let far = rect.height   // generous overshoot, clipped by the egg anyway

        p.move(to: CGPoint(x: pts[0].x, y: pts[0].y))
        for pt in pts.dropFirst() { p.addLine(to: pt) }

        if below {
            p.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: rect.maxY + far))
            p.addLine(to: CGPoint(x: pts[0].x, y: rect.maxY + far))
        } else {
            p.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: rect.minY - far))
            p.addLine(to: CGPoint(x: pts[0].x, y: rect.minY - far))
        }
        p.closeSubpath()
        return p
    }
}

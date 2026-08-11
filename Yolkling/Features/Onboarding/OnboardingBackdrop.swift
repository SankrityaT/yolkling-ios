import SwiftUI

/// The living background behind onboarding.
///
/// Onboarding used to be `YolkColor.shell.ignoresSafeArea()` — a flat cream rectangle
/// behind ten crossfading screens. Nothing on the screen moved except the creature, and
/// a still background is most of why a flow reads as a slideshow rather than as a place.
///
/// This is a `MeshGradient` whose interior control points drift on a slow, continuous
/// clock. Three things make it worth the pixels:
///
/// - **It is tinted by the creature.** `tint` is the vibe colour, so the room the player
///   is standing in takes on the colour of the thing they are making. During the quiz,
///   where every answer changes the creature, the whole screen shifts with it. That is a
///   connection between background and content that a static colour cannot express.
/// - **The edges are pinned.** Only the interior points move. If the corner points drift
///   the gradient visibly swims at the screen edge, which looks like a bug rather than
///   like light.
/// - **It stays quiet.** The tint is mixed at low strength into an eggshell base, because
///   this sits behind body copy that has to stay readable, and because the app's whole
///   look is warm paper. A loud mesh would be a different app.
///
/// Pure code, no assets — same rule as the creature and the card laminates.
struct OnboardingBackdrop: View {
    /// The creature's current colour. Drives the tint so the background belongs to them.
    var tint: Color = YolkColor.yolk
    /// How strongly the tint reads. Small on purpose.
    var strength: Double = 0.22

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                // A single frozen frame of the same mesh. Reduce Motion should not mean
                // "lose the design", it should mean "stop moving" — so the player still
                // gets the tinted paper, just without the drift.
                mesh(t: 0)
            } else {
                TimelineView(.animation) { ctx in
                    mesh(t: ctx.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .ignoresSafeArea()
        // The tint crossfades when the quiz changes the creature's colour, rather than
        // snapping. Slow, because this is ambient and a fast background change reads as
        // a flash.
        .animation(.easeInOut(duration: 0.9), value: tint)
    }

    private func mesh(t: TimeInterval) -> some View {
        MeshGradient(width: 3, height: 3, points: points(t: t), colors: colors,
                     background: YolkColor.shell)
    }

    /// A 3x3 lattice. Corners and edge-midpoints are pinned; only the four points that
    /// are not on the boundary of the visible rect are free to drift.
    ///
    /// With a 3x3 mesh only the centre point is strictly interior, so the edge midpoints
    /// drift *along* their edge only — sliding, never leaving it. That keeps the boundary
    /// exact while still giving the interior something to do.
    private func points(t: TimeInterval) -> [SIMD2<Float>] {
        func wob(_ speed: Double, _ phase: Double, _ amount: Double) -> Float {
            Float(sin(t * speed + phase) * amount)
        }

        // Deliberately unrelated speeds. Shared or harmonically related periods make the
        // whole field pulse in lockstep, which reads as a heartbeat rather than as drift.
        let topMid    = SIMD2<Float>(0.5 + wob(0.21, 0.0, 0.16), 0.0)
        let leftMid   = SIMD2<Float>(0.0, 0.5 + wob(0.17, 1.3, 0.14))
        let centre    = SIMD2<Float>(0.5 + wob(0.13, 2.1, 0.13),
                                     0.5 + wob(0.19, 0.7, 0.11))
        let rightMid  = SIMD2<Float>(1.0, 0.5 + wob(0.15, 3.4, 0.14))
        let bottomMid = SIMD2<Float>(0.5 + wob(0.11, 4.2, 0.16), 1.0)

        return [
            SIMD2<Float>(0, 0),  topMid,   SIMD2<Float>(1, 0),
            leftMid,             centre,   rightMid,
            SIMD2<Float>(0, 1),  bottomMid, SIMD2<Float>(1, 1),
        ]
    }

    /// Eggshell everywhere, with the creature's colour pooling toward the top where the
    /// creature itself sits, and the warmer `shell2` sinking to the bottom so the screen
    /// has a floor. Nine colours for the nine lattice points, row-major.
    ///
    /// Every colour here is **opaque**, mixed rather than alpha-blended. A mesh built from
    /// translucent colours composites against the gradient's own `background` (`.clear` by
    /// default), so at the root of a view it would resolve against nothing at all — the
    /// tint would come out muddy or, on a dark system backdrop, wrong. Mixing in perceptual
    /// space also keeps a saturated vibe like grape from going grey on the way to cream,
    /// which is what a naive RGB lerp does to complementary colours.
    private var colors: [Color] {
        let base = YolkColor.shell
        let warm = YolkColor.shell2
        let near = base.mix(with: tint, by: strength)
        let far  = base.mix(with: tint, by: strength * 0.45)

        return [
            base, near, base,
            far,  near, far,
            warm, warm, warm,
        ]
    }
}

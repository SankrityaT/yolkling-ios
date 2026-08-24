import SwiftUI

/// The Yolkling Plus supporter glow.
///
/// This exists because `PlusView` sells it. That paywall's own doc comment records that
/// the perk list once advertised five features that were never built, and that selling
/// unimplemented functionality is a Guideline 3.1.2 rejection as well as a plain lie to
/// the person paying. The glow was the one claim that survived that cleanup without ever
/// being implemented: `isPlus` reached two text badges and never reached the creature.
///
/// **Deliberately a ring, not a filled bloom.** The filled bloom is already taken:
/// `FoundingAura` uses exactly that for founding species. A supporter who also owns a
/// founding creature would otherwise get two coloured clouds competing for the same
/// pixels, and neither would read. A ring lights the creature from around its edge
/// instead of sitting it in a haze, so the two compose rather than fight.
///
/// **Warm and low contrast on purpose.** This should say "someone is keeping this alive",
/// never "this player paid". A cozy creature with a rank badge welded to it would be a
/// worse creature, and the subscription is explicitly framed as support rather than
/// power. See docs/MONETIZATION.md.
///
/// Pure function of `t`, like everything else the creature draws, so `frozenAt:` stays
/// reproducible and this is screenshot-verifiable.
///
/// Lives in `Core/Creature` and takes plain values, NOT a `SubscriptionStore`. That
/// directory compiles into the widget target, and reaching for the store here would drag
/// RevenueCat into the widget and break its build. Callers pass the flag down.
struct SupporterGlow: View {
    let size: CGFloat
    let t: Double
    var reduceMotion: Bool = false

    var body: some View {
        // 0.11 Hz against the creature's own 0.15 Hz breath. Close enough to feel like the
        // same living thing, far enough that they drift in and out of phase instead of
        // locking into one synchronised throb.
        let pulse = reduceMotion ? 1 : 1 + 0.035 * sin(2 * .pi * 0.11 * t)
        // 1.16, not something tighter. At 1.06 the ring sat exactly on the body's edge,
        // which was fine on a green or blue creature and nearly invisible on the default
        // yellow one: gold light on a gold body has nothing to separate against. Pushed
        // out here it sits in the cream background instead, where amber always reads. The
        // brand creature is yellow, so the yellow case is the one that has to work.
        let d = size * 1.16 * pulse
        // One turn every 20s. Slow enough to be noticed only on a second look, which is
        // the correct amount of attention for a cosmetic that costs money.
        let spin = reduceMotion ? 0 : t * 18

        ZStack {
            // Outer bloom. This is the part seen in peripheral vision and the reason the
            // creature reads as lit rather than outlined.
            Circle()
                .fill(YolkColor.yolkDeep.opacity(0.26))
                .frame(width: d * 1.10, height: d * 1.10)
                .blur(radius: size * 0.16)

            // The ring. Blurred past the point of being an outline, because a hard edge
            // here would look like a selection state rather than light.
            Circle()
                .strokeBorder(
                    AngularGradient(
                        stops: [
                            // Deep amber carries the ring, not the pale lemon. On cream
                            // the pale end is the invisible one, so the SATURATED tone has
                            // to be the base and the light tone only the travelling sheen.
                            .init(color: YolkColor.yolkDeep.opacity(0.62), location: 0.00),
                            .init(color: YolkColor.lemon.opacity(0.95),    location: 0.28),
                            .init(color: YolkColor.yolkDeep.opacity(0.62), location: 0.55),
                            .init(color: YolkColor.lemon.opacity(0.80),    location: 0.80),
                            .init(color: YolkColor.yolkDeep.opacity(0.62), location: 1.00),
                        ],
                        center: .center,
                        angle: .degrees(spin)
                    ),
                    lineWidth: size * 0.05
                )
                .frame(width: d, height: d)
                .blur(radius: size * 0.038)
        }
        // Decorative light. VoiceOver already announces the creature itself, and "glowing
        // circle" would be noise between the user and their pet.
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

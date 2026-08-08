import SwiftUI

/// The glow behind an item, scaled to how rare it is.
///
/// Rarity has always been on every `Cosmetic` and has never been drawn — an epic looked
/// exactly like a common with a bigger number next to it. This is the thing that makes
/// rarity *felt* rather than labelled, which is most of why card games feel good: you
/// know what you pulled before you read anything.
///
/// Built on the same idea as `FoundingFlair` (aura / halo / shimmer), but keyed on
/// `Rarity` instead of a specific founding species, so it works behind anything —
/// a shop card, a wardrobe tile, a reveal.
///
/// Everything derives from `t`, exactly like `YolkMotion`, so it's deterministic:
/// `frozenAt` renders one reproducible frame for share cards, the widget, and snapshot
/// tests, and Reduce Motion flattens it to a static glow rather than removing the signal.
struct RarityAura: View {
    let rarity: Rarity
    var size: CGFloat = 90
    /// Render a single fixed frame instead of animating.
    var frozenAt: Double? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if rarity == .common {
            // Common gets nothing. If everything glows, nothing reads as rare.
            EmptyView()
        } else if let frozenAt {
            layers(t: frozenAt, animate: false)
        } else if reduceMotion {
            layers(t: Self.posedT, animate: false)
        } else {
            TimelineView(.animation) { ctx in
                layers(t: ctx.date.timeIntervalSince1970, animate: true)
            }
        }
    }

    /// A pleasant fixed frame: sparkles spread out, glow mid-breath.
    static let posedT: Double = 1.4

    // MARK: Palette

    private var tint: [Color] {
        switch rarity {
        case .common: []
        case .rare:   [Color(hex: 0x8FD0FF), Color(hex: 0xB39BE8)]      // cool, quiet
        case .epic:   [Color(hex: 0xFFC23B), Color(hex: 0xFF94C2)]      // warm, loud
        }
    }

    private var sparkleCount: Int { rarity == .epic ? 5 : 3 }

    @ViewBuilder
    private func layers(t: Double, animate: Bool) -> some View {
        let breath = animate ? 1 + 0.05 * sin(2 * .pi * 0.18 * t) : 1.02

        ZStack {
            // Glow. Two offset circles on epic so the colour moves through it.
            if let a = tint.first {
                Circle().fill(a.opacity(rarity == .epic ? 0.34 : 0.24))
                    .frame(width: size * 1.02 * breath, height: size * 1.02 * breath)
                    .blur(radius: size * 0.16)
            }
            if rarity == .epic, tint.count > 1 {
                Circle().fill(tint[1].opacity(0.28))
                    .frame(width: size * 0.88 * breath, height: size * 0.88 * breath)
                    .blur(radius: size * 0.16)
                    .offset(x: size * 0.06, y: -size * 0.05)
            }

            // A slow ring, epic only. Rotation is the clearest "this one is special"
            // signal available without adding another colour.
            if rarity == .epic {
                Circle()
                    .strokeBorder(
                        AngularGradient(colors: [tint[0].opacity(0.0), tint[0].opacity(0.7),
                                                 tint[1].opacity(0.7), tint[0].opacity(0.0)],
                                        center: .center),
                        lineWidth: size * 0.022
                    )
                    .frame(width: size * 0.94, height: size * 0.94)
                    .rotationEffect(.degrees(animate ? t * 26 : 42))
            }

            // Drifting sparkles. Positions come from a stateless hash of the index, so
            // they're scattered rather than evenly spaced, and identical every render.
            ForEach(0..<sparkleCount, id: \.self) { i in
                let a = Self.hash01(i, salt: 0x51) * 2 * .pi
                let r = 0.36 + 0.12 * Self.hash01(i, salt: 0x9C)
                let drift = animate ? sin(2 * .pi * 0.22 * t + Double(i)) : 0.3
                let twinkle = animate ? 0.45 + 0.55 * abs(sin(2 * .pi * 0.5 * t + Double(i) * 1.3)) : 0.8

                Image(systemName: "sparkle")
                    .font(.system(size: size * (rarity == .epic ? 0.13 : 0.1)))
                    .foregroundStyle(tint[i % tint.count])
                    .opacity(twinkle)
                    .offset(x: cos(a) * size * r,
                            y: sin(a) * size * r + drift * size * 0.03)
            }
        }
        .allowsHitTesting(false)
    }

    /// Same SplitMix64 finaliser as YolkMotion — stateless, so a sparkle sits in the same
    /// place on every device and in every snapshot.
    private static func hash01(_ i: Int, salt: UInt64) -> Double {
        var x = UInt64(bitPattern: Int64(i)) &+ (salt &* 0x9E37_79B9_7F4A_7C15)
        x ^= x >> 30; x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27; x = x &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return Double(x >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

#Preview {
    HStack(spacing: 30) {
        ForEach([Rarity.common, .rare, .epic], id: \.self) { r in
            ZStack {
                RarityAura(rarity: r, size: 90)
                Circle().fill(Color(hex: 0xFFC23B)).frame(width: 54, height: 54)
            }
            .frame(width: 110, height: 110)
        }
    }
    .padding(40)
    .background(YolkColor.shell)
}

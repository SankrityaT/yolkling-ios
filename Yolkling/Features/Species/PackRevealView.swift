import SwiftUI

/// The pack opening: a face-down card you scratch to find out who you found.
///
/// This is the EARNED variable reward — caring discovers a new friend — given a wrapper
/// worth opening. No cash ever touches the randomness, so it is a reward of the hunt and
/// never a loot box (see docs/MONETIZATION.md).
///
/// It used to be a wiggling egg you tapped once. The egg was fine and the tap was not: one
/// tap is a button, and a button cannot build anticipation because there is no moment
/// between deciding and knowing. Scratching puts that moment in your hand and makes it as
/// long as you want it to be. It is also the same gesture as a real scratch card, so there
/// is nothing to explain.
struct PackRevealView: View {
    let species: Species

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    /// Tapped "love it". The creature answers before the sheet closes.
    @State private var loved = false

    /// The number is the species' fixed place in the Dex, not the player's progress — two
    /// people who find the same creature should be holding the same card.
    ///
    /// `dexNumber` is nil for anything outside a completable set (a founding grant), and
    /// `YolkCardFace.species` prints no serial when it is, which is what should happen:
    /// better nothing than a made-up "no. 000".
    private var face: YolkCardFace {
        .species(species,
                 discovered: .now,
                 number: SpeciesSets.dexNumber(of: species.id),
                 outOf: SpeciesSets.dexTotal)
    }

    private var smittenFace: YolkCardFace {
        var f = face
        f.expression = .smitten
        return f
    }

    /// "love it" is not just a dismiss button. The creature answers first: heart eye, wink,
    /// and a burst of hearts, and only then does the sheet close.
    ///
    /// The delay is the whole point. A tap that closes instantly gives you nothing back for
    /// the tap, and this is the last beat of a discovery — the one place in the flow where
    /// spending half a second is the reward rather than a cost.
    private func loveIt() {
        guard !loved else { return }
        Haptics.shared.pet()
        withAnimation(.spring(duration: 0.45, bounce: 0.4)) { loved = true }
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.15 : 1.1))
            dismiss()
        }
    }

    var body: some View {
        ZStack {
            YolkColor.shell.ignoresSafeArea()

            VStack(spacing: YolkSpace.md) {
                Spacer(minLength: 0)

                Text(revealed ? "a new friend" : "a little gift")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .tracking(2).textCase(.uppercase).foregroundStyle(YolkColor.muted)
                    .animation(.easeInOut(duration: 0.3), value: revealed)

                CardScratchView(
                    // Once loved, the card's creature goes heart-eyed and winks. The face
                    // is a value, so swapping the expression is enough — `YolklingView`
                    // interpolates from whatever pose it was in, which is why this reads as
                    // the creature reacting rather than as a cut to a different picture.
                    face: loved ? smittenFace : face,
                    width: 290,
                    // The seam is kept, so the screenshot pipeline can still capture an
                    // opened pack without simulating a drag.
                    revealImmediately: ProcessInfo.processInfo.environment["YOLK_PACK_OPEN"] != nil
                ) {
                    withAnimation(.snappy) { revealed = true }
                }

                caption

                Spacer(minLength: 0)

                if revealed {
                    Button { loveIt() } label: {
                        Text(loved ? "♥" : "love it")
                            .font(YolkType.body.weight(.semibold))
                            .foregroundStyle(YolkColor.shell)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(YolkColor.ink, in: Capsule())
                            .scaleEffect(loved ? 0.96 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(loved)
                    .padding(.horizontal, YolkSpace.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, YolkSpace.lg)

            // IN FRONT of the card, not behind it. As the ZStack's first child the hearts
            // rendered underneath and were completely invisible.
            if loved { HeartBurst() }
        }
        .onAppear {
            // Screenshot seam for the love beat itself. Without it there is no way to
            // capture the heart-eyed wink: it lives inside a one-second window that ends in
            // a dismiss, which no screenshot tool can reliably hit.
            if ProcessInfo.processInfo.environment["YOLK_PACK_LOVED"] != nil { loved = true }
        }
    }

    /// The species' own words, once you have uncovered enough to have earned them.
    ///
    /// Held back until the reveal on purpose. The personality line names the creature's
    /// character, and printing it over a card you have not scratched yet would answer the
    /// question the card is asking. Height is reserved either way so the layout does not
    /// jump when it arrives.
    private var caption: some View {
        VStack(spacing: 4) {
            if revealed {
                Text(species.name)
                    .font(YolkType.heading).foregroundStyle(YolkColor.ink)
                Text(species.personality)
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, YolkSpace.lg)
                // Tilt is not discoverable on its own. Nobody turns a phone at a picture
                // unless something suggests it, and the whole card system is built around
                // that gesture — so it gets said once, plainly, at the only moment the
                // player is definitely looking at the card.
                //
                // Dropped as soon as they love it: by then the beat has moved on, and a
                // tip competing with the payoff is just noise.
                if !loved {
                    Text("tilt your phone to catch the light")
                        .font(.caption2).foregroundStyle(YolkColor.muted)
                        .padding(.top, 2)
                        .transition(.opacity)
                }
            } else {
                Text("scratch to see who it is")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
        }
        .frame(height: 82)
        .animation(.easeInOut(duration: 0.3), value: revealed)
    }
}

/// Hearts drifting up past the card, for the "love it" beat.
///
/// Positions and timings come from the same stateless SplitMix64 hash the creature and the
/// laminates use, so the burst is scattered rather than evenly spaced and identical on
/// every device. Rise and fade are one `animation` on a single flag: a per-heart animator
/// would be a dozen more views for something on screen for a second.
private struct HeartBurst: View {
    @State private var up = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let count = 14

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<Self.count, id: \.self) { i in
                let x = Holo.hash01(i, salt: 0x11EA) * geo.size.width
                let size = 12 + Holo.hash01(i, salt: 0x22EA) * 16
                let drift = (Holo.hash01(i, salt: 0x33EA) - 0.5) * 70
                // Staggered starts, so they leave in a scatter rather than a wall.
                let delay = Holo.hash01(i, salt: 0x44EA) * 0.45

                Image(systemName: "heart.fill")
                    .font(.system(size: size))
                    .foregroundStyle(YolkColor.pink.opacity(0.75))
                    .position(x: x, y: geo.size.height * 0.72)
                    .offset(y: up ? -geo.size.height * 0.62 : 0)
                    .offset(x: up ? drift : 0)
                    .opacity(up ? 0 : 0.95)
                    .scaleEffect(up ? 1.25 : 0.5)
                    .animation(.easeOut(duration: 1.15).delay(delay), value: up)
            }
        }
        .allowsHitTesting(false)
        // Reduce Motion keeps the hearts (they carry the meaning) and skips the travel.
        .onAppear { if !reduceMotion { up = true } }
    }
}

#Preview {
    PackRevealView(species: SpeciesCatalog.all.first { $0.id == "garden-firefleur" }!)
}

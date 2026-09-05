import SwiftUI
import YolklingCore

/// Your yolkling walking back in, carrying what it found.
///
/// The wander was always the one moment in this app where the creature has a life of its
/// own: nobody sends it, it just goes, and it comes back with something. But it was
/// invisible. A species would simply *appear* in the collection after a check-in, so the
/// most characterful thing in the app read as a database row.
///
/// **You watch the homecoming, not the departure.** That is the honest framing, not a
/// staging choice: the wander resolves on app open, so "it just got back" is literally
/// true, whereas showing it leave would be a cutscene about a thing that already happened.
/// It also puts you in the better seat. You did not send it, you do not know where it went,
/// and you find out what it found at the same moment it does.
///
/// Three beats: it walks in, it offers you the card, you scratch it.
struct WanderHomeView: View {
    let vibe: Vibe
    let name: String
    /// What it brought home.
    let face: YolkCardFace

    var onDone: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var arrived = false
    @State private var offering = false
    @State private var bob = false
    /// The card has been scratched open. Holds the sheet still and shows the way out.
    @State private var revealed = false

    private var caption: String {
        if revealed { return "\(name) brought this home" }
        if offering { return "look what it found" }
        if arrived { return "\(name) is back" }
        return "something's coming up the path"
    }

    var body: some View {
        ZStack {
            YolkColor.shell.ignoresSafeArea()

            VStack(spacing: YolkSpace.md) {
                Spacer(minLength: 0)

                Text(caption)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .tracking(2).textCase(.uppercase)
                    .foregroundStyle(YolkColor.muted)
                    .animation(.easeInOut(duration: 0.35), value: caption)
                    .contentTransition(.opacity)

                stage

                Spacer(minLength: 0)

                if revealed {
                    Button {
                        Haptics.shared.tick()
                        onDone()
                        dismiss()
                    } label: {
                        Text("keep it")
                            .font(YolkType.body.weight(.semibold))
                            .foregroundStyle(YolkColor.shell)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(YolkColor.ink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, YolkSpace.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, YolkSpace.lg)

        }
        // In an OVERLAY, not as a ZStack child. Making the ZStack .topLeading to host it
        // re-aligned every sibling, shoving the creature and card against the leading
        // edge with dead space on the right.
        //
        // A fullScreenCover cannot be swiped away, and the only other exit is finishing
        // the scratch, so someone who sets the phone down mid-reveal was stranded.
        .overlay(alignment: .topLeading) {
            YolkCloseButton { onDone(); dismiss() }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.top, YolkSpace.sm)
        }
        .task { await run() }
    }

    /// The creature and, once it has stopped walking, the card.
    ///
    /// Laid out in a ZStack so the card can grow out from BEHIND the creature rather than
    /// appearing beside it. It reads as something being carried and then held up, which is
    /// the whole point; a card that fades in next to the creature reads as a UI element.
    private var stage: some View {
        ZStack {
            if offering {
                CardScratchView(face: face, width: 270) {
                    // Do NOT dismiss here. This used to close the sheet 1.2s after the
                    // reveal, which took the card away at the exact moment it became
                    // worth looking at: you scratch it, it flips, and it is gone before
                    // you have read it. The whole beat is the payoff for scratching.
                    //
                    // It ends when the person says so, like the pack reveal does.
                    withAnimation(.snappy) { revealed = true }
                }
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }

            YolklingView(vibe: vibe, expression: offering ? .excited : .happy,
                         size: offering ? 74 : 150)
                // Walks in from off to the left, then steps aside to make room for the card.
                .offset(x: arrived ? (offering ? -128 : 0) : -230,
                        y: offering ? 108 : (bob ? -7 : 0))
                .zIndex(1)
                // Decoration, not a control. Drawn over the card's lower left corner, so
                // while it was hit-testable it swallowed every scratch that started
                // there: a dead patch of card that gave no mark and no texture, which
                // reads as the scratch only working in certain spots.
                .allowsHitTesting(false)
        }
        .frame(height: 420)
    }

    private func run() async {
        guard !reduceMotion else {
            // No walk, no wait. The card is what matters and the journey is decoration.
            arrived = true
            offering = true
            return
        }

        // A small bob for the walk. The creature has no walk cycle (it has no legs to speak
        // of), so travel plus a vertical bounce is the whole gait, which is also how it
        // moves everywhere else in the app.
        withAnimation(.easeInOut(duration: 0.34).repeatForever(autoreverses: true)) { bob = true }
        withAnimation(.easeOut(duration: 1.5)) { arrived = true }

        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(.easeInOut(duration: 0.2)) { bob = false }
        Haptics.shared.pop()
        try? await Task.sleep(for: .seconds(0.35))
        withAnimation(.spring(duration: 0.6, bounce: 0.35)) { offering = true }
    }
}

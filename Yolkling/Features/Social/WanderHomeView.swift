import SwiftUI

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

    private var caption: String {
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
            }
            .padding(.bottom, YolkSpace.lg)
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
                    // Let the scratch land before the sheet moves.
                    Task {
                        try? await Task.sleep(for: .seconds(1.2))
                        onDone()
                        dismiss()
                    }
                }
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }

            YolklingView(vibe: vibe, expression: offering ? .excited : .happy,
                         size: offering ? 74 : 150)
                // Walks in from off to the left, then steps aside to make room for the card.
                .offset(x: arrived ? (offering ? -128 : 0) : -230,
                        y: offering ? 108 : (bob ? -7 : 0))
                .zIndex(1)
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

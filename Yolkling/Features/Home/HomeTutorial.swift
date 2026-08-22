import SwiftUI

/// The first-run tour.
///
/// The previous version had three problems, and they compounded:
///
/// **It covered what it was describing.** The beat that says "tap decorate to place your
/// stuff" sat directly over the room and the Decorate button. You read about a control
/// you could not see, then had to go find it from memory afterwards.
///
/// **The card jumped.** Each beat carried a `bottom: Bool` that placed it at either 46%
/// or 60% of the screen, and the beats alternated — so the card hopped down, up, down,
/// up with no visible reason. Movement without a cause reads as a glitch.
///
/// **It dimmed everything.** A scrim over the whole screen during a tour of that screen
/// means the tour has nothing to point at.
///
/// Now each beat spotlights its subject: the dim gets a hole cut in it around the real
/// measured frame of the thing being talked about, and the card places itself in
/// whichever half of the screen the spotlight is not in. The card still moves, but now
/// it moves *because* the subject moved, which is legible rather than random.
struct HomeTutorial: View {
    let name: String
    /// Measured frames, supplied by HomeView.
    let anchors: [TutorialTarget: CGRect]
    var onDone: () -> Void

    @State private var step = 0

    private struct Beat {
        let eyebrow: String
        let text: String
        let target: TutorialTarget?
        let cta: String
    }

    private var beats: [Beat] {
        [
            Beat(eyebrow: "meet \(name)",
                 text: "this is \(name), your one of a kind yolk. tap them anytime to say hi.",
                 target: .creature, cta: "next"),
            Beat(eyebrow: "your real day feeds them",
                 text: "steps and sleep are what nourish \(name). the more you look after yourself, the better their day goes.",
                 target: .living, cta: "next"),
            Beat(eyebrow: "make it home",
                 text: "this little room is theirs and yours. tap decorate to make the space your own.",
                 target: .decorate, cta: "next"),
            Beat(eyebrow: "earn their trust",
                 text: "check in daily and care for yourself. that is how they learn to wave, celebrate your wins, and become truly yours.",
                 target: .careRow, cta: "let's go"),
        ]
    }

    private var beat: Beat { beats[min(step, beats.count - 1)] }

    /// The subject's frame, padded so the spotlight has a little air around it.
    private var hole: CGRect? {
        guard let t = beat.target, let r = anchors[t] else { return nil }
        return r.insetBy(dx: -10, dy: -10)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                SpotlightScrim(hole: hole)
                    .contentShape(Rectangle())
                    .onTapGesture { advance() }

                // The card goes to whichever half the spotlight is not in, so it can
                // never sit on top of its own subject.
                VStack(spacing: 0) {
                    if cardBelowSpotlight(in: geo.size) {
                        Spacer(minLength: 0)
                        card
                            .padding(.bottom, geo.size.height * 0.12)
                    } else {
                        card
                            .padding(.top, geo.size.height * 0.10)
                        Spacer(minLength: 0)
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
            }
        }
        .transition(.opacity)
    }

    /// True when the subject sits in the top half, so the card belongs underneath it.
    private func cardBelowSpotlight(in size: CGSize) -> Bool {
        guard let hole else { return true }
        return hole.midY < size.height * 0.5
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            HStack {
                Text(beat.eyebrow.uppercased())
                    .font(.caption2.weight(.bold)).tracking(2)
                    .foregroundStyle(YolkColor.yolkDeep)
                Spacer()
                // Dots rather than "3 / 4". A fraction invites you to count how much is
                // left; dots just say roughly where you are.
                HStack(spacing: 5) {
                    ForEach(0..<beats.count, id: \.self) { i in
                        Circle()
                            .fill(i == step ? YolkColor.ink : YolkColor.line)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            Text(beat.text)
                .font(YolkType.body).foregroundStyle(YolkColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: YolkSpace.sm) {
                Button { onDone() } label: {
                    Text("skip").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                        .padding(.vertical, 12).padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                Button { advance() } label: {
                    Text(beat.cta).font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(YolkSpace.lg)
        .background(YolkColor.shell, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .padding(.horizontal, YolkSpace.lg)
    }

    private func advance() {
        if step < beats.count - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { step += 1 }
            Haptics.shared.tick()
        } else {
            Haptics.shared.select()
            onDone()
        }
    }
}

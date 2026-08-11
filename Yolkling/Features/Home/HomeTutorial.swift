import SwiftUI
import YolklingCore

/// A short, warm first-run tour over the home screen that teaches the actual loop:
/// this is your yolk, your real day feeds it, caring for yourself earns its trust.
/// Dims the screen (the room shows through) and walks three beats. Shown once.
struct HomeTutorial: View {
    let name: String
    var onDone: () -> Void

    @State private var step = 0

    private struct Beat { let eyebrow: String; let text: String; let bottom: Bool; let cta: String }

    private var beats: [Beat] {
        [
            Beat(eyebrow: "meet \(name)",
                 text: "this is \(name), your one of a kind yolk, living in their little room. tap them anytime to say hi.",
                 bottom: false, cta: "next"),
            Beat(eyebrow: "the secret",
                 text: "your real day feeds \(name). steps and sleep are what nourish them. (time off your phone is coming soon.)",
                 bottom: true, cta: "next"),
            Beat(eyebrow: "make it home",
                 text: "this little room is theirs and yours. tap decorate to place your stuff and make the space your own.",
                 bottom: false, cta: "next"),
            Beat(eyebrow: "earn their trust",
                 text: "check in and care for yourself daily. that is how you earn their trust, and they learn to wave, celebrate your wins, and become truly yours.",
                 bottom: true, cta: "let's go"),
        ]
    }

    var body: some View {
        let beat = beats[step]
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.55).ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { advance() }

                VStack(spacing: 0) {
                    // proportional so the card sits below the creature on any screen
                    Spacer().frame(height: geo.size.height * (beat.bottom ? 0.6 : 0.46))
                    card(beat)
                    Spacer(minLength: 0)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .transition(.opacity)
    }

    private func card(_ beat: Beat) -> some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            HStack {
                Text(beat.eyebrow.uppercased()).font(.caption2.weight(.bold)).tracking(2).foregroundStyle(YolkColor.yolkDeep)
                Spacer()
                Text("\(step + 1) / \(beats.count)").font(.caption2).foregroundStyle(YolkColor.muted)
            }
            Text(beat.text)
                .font(YolkType.body).foregroundStyle(YolkColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button { advance() } label: {
                Text(beat.cta).font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
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
            withAnimation { step += 1 }
            Haptics.shared.tick()
        } else {
            Haptics.shared.select()
            onDone()
        }
    }
}

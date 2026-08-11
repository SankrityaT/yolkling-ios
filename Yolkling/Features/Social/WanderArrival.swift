import SwiftUI
import YolklingCore

/// "Your yolkling went somewhere while you were away."
///
/// The moment the whole social design is built around: a surprise you did not ask for,
/// waiting when you open the app. `RETENTION.md` ranks this above every other reward in
/// the app, and it's the reason drift exists at all.
///
/// **What it brings back is a picture of the room, not a message from a person.** That
/// distinction is load-bearing: fabricating a note from a real stranger who never wrote
/// one would be a lie, and this app's whole position is that it doesn't lie to you. The
/// room is real, the visit is real, and the postcard is genuinely of somewhere your
/// creature went.
struct WanderArrival: View {
    let target: DriftTarget
    let vibe: Vibe
    @State var store: SocialStore
    let myName: String
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var composing = false
    @State private var shareURL: URL?
    @State private var rendering = false

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            Spacer(minLength: 0)

            Text("your yolkling wandered off")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("it found a door open and let itself in.")
                .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)

            room
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, YolkSpace.lg)

            Text("it brought back a postcard")
                .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)

            Spacer(minLength: 0)

            VStack(spacing: YolkSpace.sm) {
                Button { composing = true } label: {
                    Text("leave them a note")
                        .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)

                if let shareURL {
                    ShareLink(item: shareURL) {
                        Text("share the postcard")
                            .font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.ink)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(YolkColor.shell2, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button { dismiss() } label: {
                    Text("maybe later").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, YolkSpace.lg)
            .padding(.bottom, YolkSpace.lg)
        }
        .background(YolkColor.shell)
        .sheet(isPresented: $composing) {
            PostcardCompose(subject: .stranger(target), store: store, vibe: vibe, onReward: onReward)
                .presentationDetents([.medium, .large])
        }
        .task { await renderCard() }
    }

    @ViewBuilder private var room: some View {
        if let snap = target.snapshot {
            RoomView(vibe: snap.makeVibe(name: target.displayName), expression: snap.expression,
                     theme: snap.theme, outfit: snap.outfit, decor: snap.decor)
        } else {
            RoomView(vibe: .yolk, expression: .happy, theme: RoomThemes.cozy)
        }
    }

    /// Renders the share card off the room it actually visited. Uses the existing
    /// `frozenAt:` seam — ImageRenderer can't capture a live TimelineView.
    private func renderCard() async {
        guard !rendering, let snap = target.snapshot else { return }
        rendering = true
        shareURL = ShareCardRenderer.render(
            snapshot: snap,
            creatureName: myName,
            phrase: "went wandering, found this",
            inviteCode: store.myCode
        )
    }
}

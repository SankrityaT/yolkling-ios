import SwiftUI
import YolklingCore

/// One card, full screen, live: tilt it, then share it.
///
/// This is what the Dex taps into, and it is the first place in the app where a card is
/// something a player can just *hold*. Everywhere else a card is a beat in a flow (a pack
/// opening, a profile row); here it is the whole screen and the only thing to do is turn it.
struct CardDetailView: View {
    let face: YolkCardFace
    /// Printed into the shared image. Empty is handled: the card renders without a code
    /// rather than with a dangling `yolkling.com/add/`.
    var inviteCode: String = ""
    /// The species this card is of, when it is one. Enables "ask them over" — nil on a
    /// bond card, which is already home.
    var species: Species? = nil
    /// Whether this species is currently round at yours.
    var isVisiting: Bool = false
    /// Invite or send home. nil hides the button entirely, for the surfaces that have no
    /// room to put anyone in (a friend's collection).
    var onToggleVisit: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var rendering = false

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            header

            Spacer(minLength: 0)
            YolkCard(face: face, width: 300)
            Spacer(minLength: 0)

            Text("tilt your phone to catch the light")
                .font(.caption2).foregroundStyle(YolkColor.muted)

            VStack(spacing: YolkSpace.sm) {
                visitButton
                shareButton
            }
            .padding(.horizontal, YolkSpace.lg)
            .padding(.bottom, YolkSpace.lg)
        }
        .padding(.top, YolkSpace.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(YolkColor.shell.ignoresSafeArea())
        .task { await renderShare() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(face.name).font(YolkType.heading).foregroundStyle(YolkColor.ink)
                if let species = face.species, let family = face.family {
                    Text("\(species) · \(family)")
                        .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
            }
            Spacer()
            Button { Haptics.shared.tick(); dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft).padding(10)
                    .background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg)
    }

    /// Ask them round, or send them home.
    ///
    /// This is the whole point of the collection existing. A Dex you look at once is a
    /// catalogue; a species that turns up in your room is a reason to have wanted it. And
    /// it is deliberately the ONLY thing you can do with a found species — no equipping,
    /// no levelling, nothing that makes owning more of them strictly better.
    @ViewBuilder private var visitButton: some View {
        if let onToggleVisit {
            Button {
                Haptics.shared.pop()
                onToggleVisit()
            } label: {
                HStack(spacing: 7) {
                    YolkGlyph(kind: isVisiting ? .yolk : .friends, size: 16)
                    Text(isVisiting ? "send them home" : "ask them over")
                        .font(YolkType.body.weight(.semibold))
                }
                .foregroundStyle(isVisiting ? YolkColor.ink : YolkColor.shell)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(isVisiting ? YolkColor.shell2 : YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    /// Appears only once the PNG exists.
    ///
    /// Following the pattern `WanderArrival` already uses: no spinner and no disabled state,
    /// the button simply is not there until there is something to share. A share button that
    /// can fail is worse than one that arrives a beat late.
    @ViewBuilder private var shareButton: some View {
        if let shareURL {
            ShareLink(item: shareURL) {
                Text("share this card")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func renderShare() async {
        guard !rendering else { return }
        rendering = true
        shareURL = ShareCardRenderer.renderCard(face: face, inviteCode: inviteCode)
    }
}

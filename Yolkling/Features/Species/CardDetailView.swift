import SwiftUI

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

            shareButton
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

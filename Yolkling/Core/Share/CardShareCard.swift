import SwiftUI

/// A card, framed for posting.
///
/// The holo card on its own is the wrong shape for a feed (63×88 is tall and narrow) and
/// carries no way back to the app. This wraps it: shell background, the card at a readable
/// size, and the invite code underneath.
///
/// Same load-bearing constraints as ``PostcardCard``, for the same reason — `ImageRenderer`
/// draws outside the view hierarchy:
/// - **No `@Environment`.** It does not flow in, so anything reading it renders wrong.
/// - **No `@Observable` stores, no `Haptics`.** Everything arrives as a value, so identical
///   inputs always produce an identical image.
/// - **No materials or top-level `.blur`.** Dropped inconsistently.
/// - **The card renders frozen.** `ImageRenderer` cannot capture `TimelineView(.animation)`
///   or a `CADisplayLink`, so a live card would come out blank. `YolkCard(frozenAt:)` exists
///   for exactly this, and the pose is a fixed one so two renders of the same card match.
struct CardShareCard: View {
    let face: YolkCardFace
    /// Rendered into the IMAGE, not the caption. Captions get stripped when people repost;
    /// pixels do not. This is what closes the loop.
    let inviteCode: String

    static let size = CGSize(width: 360, height: 450)

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            YolkCard(face: face, width: 232,
                     interactive: false,
                     frozenAt: YolkCard.posed)

            Spacer(minLength: 0)

            VStack(spacing: 3) {
                Text(face.kind == .bond ? "my yolkling" : "found a \(face.rarity.rawValue)")
                    .font(YolkType.bodySmall)
                    .foregroundStyle(YolkColor.inkSoft)
                if !inviteCode.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle").font(.system(size: 9, weight: .bold))
                        Text("yolkling.com/add/\(inviteCode)").font(YolkType.label)
                    }
                    .foregroundStyle(YolkColor.muted)
                }
            }
            .padding(.bottom, 18)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(YolkColor.shell)
    }
}

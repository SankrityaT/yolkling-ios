import SwiftUI

/// The image a player posts to Instagram or TikTok. This is the app's primary **open**
/// growth loop: unlike a friend visit, it works with zero friends and lands in front of
/// people who don't have Yolkling.
///
/// Deliberate constraints, all of them load-bearing for `ImageRenderer`:
/// - **No `@Environment` values.** `ImageRenderer` renders outside the view hierarchy,
///   so environment doesn't flow in and anything depending on it silently renders wrong.
/// - **No `@Observable` stores, no `Haptics`.** Everything arrives as a plain value, so
///   the same inputs always produce the same image.
/// - **No materials or `.blur` at the top level.** `ImageRenderer` drops them
///   inconsistently.
/// - **The creature renders through `YolklingView(frozenAt:)`.** `ImageRenderer` cannot
///   capture `TimelineView(.animation)` — it renders a single frame outside the run
///   loop, so a live creature would come out blank. That seam exists for this.
///
/// Sized in points; `ShareCardRenderer` rasterises at 3× for a 1080×1350 PNG (Instagram's
/// largest feed slot, and it crops acceptably to a 1080×1920 story).
struct PostcardCard: View {
    let snapshot: RoomSnapshot
    let creatureName: String
    let phrase: String
    /// The sender's referral code. Rendered into the image on purpose — captions get
    /// stripped when people repost, pixels don't. This is what closes the loop.
    let inviteCode: String

    static let size = CGSize(width: 360, height: 450)

    private var vibe: Vibe { snapshot.makeVibe(name: creatureName) }

    var body: some View {
        VStack(spacing: 0) {
            scene
            caption
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(YolkColor.shell)
    }

    // MARK: Scene

    private var scene: some View {
        ZStack {
            RoomView(vibe: vibe, expression: snapshot.expression, theme: snapshot.theme,
                     outfit: snapshot.outfit, decor: snapshot.decor, showCreature: false)

            GeometryReader { geo in
                YolklingView(vibe: vibe,
                             expression: snapshot.expression,
                             size: geo.size.height * RoomView.creatureSpot.size,
                             outfit: snapshot.outfit,
                             frozenAt: YolklingView.posedT)
                    .position(x: geo.size.width * RoomView.creatureSpot.x,
                              y: geo.size.height * RoomView.creatureSpot.y)
            }
        }
        .frame(height: Self.size.height * 0.66)
        .clipped()
    }

    // MARK: Caption

    private var caption: some View {
        VStack(spacing: 10) {
            Text("“\(phrase)”")
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            Text("— \(creatureName)")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))
                Text("yolkling.com/add/\(inviteCode)")
                    .font(YolkType.label)
            }
            .foregroundStyle(YolkColor.muted)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PostcardCard(
        snapshot: RoomSnapshot(colorHex: 0xFFC23B, styleRaw: "plain", accentHex: nil,
                               patternRaw: "none", activeFoundingID: nil, moodRaw: "happy",
                               themeID: "room-cozy", decorIDs: [], outfitIDs: []),
        creatureName: "Yolky",
        phrase: "came by to say hi",
        inviteCode: "YOLK-AB12"
    )
    .border(YolkColor.line)
}

import SwiftUI
import YolklingCore

/// The yolk's little room: a cozy code-drawn interior (wall, floor, window, wall
/// art, rug) with the creature living in it, plus any decor the player has bought
/// and placed (RoomDecorView). Theme-driven so designers add palettes + decor
/// without rewriting this (docs/rooms/). Later this is the space friends visit (#17).
struct RoomView: View {
    var vibe: Vibe = .yolk
    var expression: YolkExpression = .happy
    var theme: RoomTheme = RoomThemes.cozy
    var outfit: [Cosmetic] = []
    /// Decor the player has placed (bought with Yolks). Rendered at each piece's
    /// fractional placement over the floor + wall.
    var decor: [RoomDecor] = []
    /// When false, the room is drawn empty (no resident creature) so a caller can
    /// overlay its own interactive creature at `creatureSpot`. Home does this so the
    /// yolk stays pettable while living in its decorated room.
    var showCreature: Bool = true
    /// Bump to make the resident creature wave (used when you wave at a friend so
    /// their yolk waves back). Passed straight through to the YolklingView.
    var waveToken: Int = 0

    /// A species you have found, come round for a bit.
    ///
    /// **A guest, not a second pet.** It has no stats, gains nothing from your care, and
    /// cannot be levelled, equipped or made "active" — care means care for YOUR creature,
    /// and the moment a second one benefits from it, owning more becomes strictly better
    /// and the whole app turns into a collection to optimise.
    ///
    /// What this fixes is the opposite problem: a Dex of 32 species you look at once and
    /// never see again. Now they turn up in the room, which is a reason to want them that
    /// is not a stat.
    var guest: Species? = nil

    /// Where the resident creature sits, as fractions of the room frame (so overlays
    /// can line up a creature exactly with where RoomView would draw one).
    static let creatureSpot = (x: 0.5, y: 0.60, size: 0.42)

    /// Off to one side and further back. Smaller than the resident and set higher in the
    /// frame, which reads as depth — the guest is across the room, not standing next to
    /// your creature as an equal.
    static let guestSpot = (x: 0.20, y: 0.52, size: 0.26)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                theme.wall
                floor(w, h)
                wallArt(w * 0.20, h * 0.17).position(x: w * 0.24, y: h * 0.24)
                window(w * 0.30, h * 0.28).position(x: w * 0.73, y: h * 0.27)
                rug(w, h)
                ForEach(decor) { d in
                    RoomDecorView(kind: d.kind)
                        .frame(width: w * d.sw, height: h * d.sh)
                        .position(x: w * d.px, y: h * d.py)
                }
                // Drawn BEFORE the resident, so if the two ever overlap your creature is
                // in front. Whose room this is should never be in question.
                if let guest {
                    YolklingView(vibe: guest.vibe, expression: .content,
                                 size: h * RoomView.guestSpot.size)
                        .position(x: w * RoomView.guestSpot.x, y: h * RoomView.guestSpot.y)
                        .allowsHitTesting(false)   // it is a visitor, not a thing to poke
                }
                if showCreature {
                    YolklingView(vibe: vibe, expression: expression, size: h * RoomView.creatureSpot.size, outfit: outfit, waveToken: waveToken)
                        .position(x: w * RoomView.creatureSpot.x, y: h * RoomView.creatureSpot.y)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.black.opacity(0.06), lineWidth: 1))
        }
    }

    // MARK: Surfaces

    private func floor(_ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .top) {
                theme.floorColor
                theme.floorEdgeColor.frame(height: h * 0.016)        // skirting where floor meets wall
                HStack(spacing: w / 6) {                              // floorboard seams
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle().fill(theme.floorEdgeColor.opacity(0.35)).frame(width: 1)
                    }
                }
            }
            .frame(height: h * 0.34)
        }
    }

    private func rug(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(theme.accentColor.opacity(0.9))
            Ellipse().strokeBorder(.white.opacity(0.55), lineWidth: 3)
            Ellipse().strokeBorder(theme.accentColor.opacity(0.6), lineWidth: 2).padding(8)
        }
        .frame(width: w * 0.66, height: h * 0.15)
        .position(x: w * 0.5, y: h * 0.85)
    }

    // MARK: Decor

    private func window(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.12)
                .fill(LinearGradient(colors: [Color(hex: 0xBFE3F2), Color(hex: 0xE9F3DA)], startPoint: .top, endPoint: .bottom))
            Capsule().fill(.white.opacity(0.85)).frame(width: w * 0.42, height: h * 0.16).offset(x: -w * 0.1, y: -h * 0.1)
            Capsule().fill(.white.opacity(0.65)).frame(width: w * 0.3, height: h * 0.12).offset(x: w * 0.16, y: h * 0.06)
            Rectangle().fill(.white).frame(width: w * 0.06)
            Rectangle().fill(.white).frame(height: h * 0.06)
            RoundedRectangle(cornerRadius: w * 0.12).strokeBorder(.white, lineWidth: w * 0.06)
        }
        .frame(width: w, height: h)
        .background(Capsule().fill(Color(hex: 0xEDDCC6)).frame(width: w * 1.12, height: h * 0.12).offset(y: h * 0.54))
    }

    private func wallArt(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.08).fill(Color(hex: 0x8A6A4A))
            ZStack {
                LinearGradient(colors: [Color(hex: 0xFCE3B8), Color(hex: 0xF7C9A0)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xFFD25A)).frame(width: w * 0.26, height: w * 0.26).offset(x: w * 0.16, y: -h * 0.1)
                Ellipse().fill(Color(hex: 0x9CCB86)).frame(width: w * 1.0, height: h * 0.5).offset(y: h * 0.34)
            }
            .clipShape(RoundedRectangle(cornerRadius: w * 0.05)).padding(w * 0.07)
        }
        .frame(width: w, height: h)
    }

}

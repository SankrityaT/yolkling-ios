import SwiftUI

/// One cosmetic, shown the way you'd actually recognise it: **worn**.
///
/// The first version drew the cosmetic floating alone in a box, and it was unreadable —
/// a crown with no head has no scale, no orientation and no context, so a 44pt shape in
/// a 72pt tile just reads as "a small yellow thing". Cosmetics are DESIGNED to sit on a
/// creature; drawing them anywhere else throws away the information that makes them
/// legible. The wardrobe grid always did this, which is why that screen reads and this
/// one didn't.
///
/// The rarity aura is dialled to a fraction of its hero strength here. At tile size a
/// full aura stops framing the item and becomes the subject — every tile glows, so no
/// tile means anything. Rarity is carried by a tinted border and a small label instead,
/// with just enough glow to hint.
///
/// Rendered `frozenAt` on purpose: a scrolling row of these would otherwise spin up one
/// live `TimelineView` per tile, which is a lot of per-frame work for decoration.
struct ItemTile: View {
    let item: Cosmetic
    var vibe: Vibe = .yolk
    var side: CGFloat = 104
    var selected: Bool = false
    var showsName: Bool = true

    private var tint: Color {
        switch item.rarity {
        case .common: YolkColor.line
        case .rare:   Color(hex: 0x8FD0FF)
        case .epic:   Color(hex: 0xFFC23B)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(YolkColor.shell2)

                RarityAura(rarity: item.rarity, size: side,
                           frozenAt: RarityAura.posedT, intensity: 0.45)

                // The item, worn. This is the whole fix.
                //
                // Nudged down slightly: hats anchor well above the creature's centre, so
                // a tall one (crown, wizard hat) grazes the tile's top edge when the
                // creature is optically centred.
                YolklingView(vibe: vibe, expression: .content,
                             size: side * 0.58, outfit: [item],
                             frozenAt: YolklingView.posedT)
                    .offset(y: side * 0.05)
            }
            .frame(width: side, height: side)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(selected ? YolkColor.ink : tint.opacity(item.rarity == .common ? 0.5 : 0.9),
                                  lineWidth: selected ? 3 : 1.5)
            )
            // Badge sits INSIDE the tile. It used to overhang by 6pt, which a horizontal
            // ScrollView happily clipped — SwiftUI clips scroll content to bounds, so any
            // decoration that pokes outside a row is invisible the moment it matters.
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(YolkColor.shell)
                        .padding(5)
                        .background(YolkColor.ink, in: Circle())
                        .padding(6)
                }
            }
            .scaleEffect(selected ? 1.04 : 1)
            .animation(.snappy(duration: 0.18), value: selected)

            if showsName {
                Text(item.name)
                    .font(YolkType.bodySmall.weight(selected ? .semibold : .regular))
                    .foregroundStyle(selected ? YolkColor.ink : YolkColor.inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .frame(width: side + 8)
                if item.rarity != .common {
                    Text(item.rarity.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
        }
    }
}

import SwiftUI

/// What you can do in a friend's room.
///
/// This was a native `Menu`, and a native menu cannot be drawn. Its rows only take `Text`
/// and `Image`, which meant SF Symbols in somebody else's line weight next to three
/// unlabelled "gift N Yolks" rows — a ragged list in an app that draws everything else
/// itself.
///
/// It was also the wrong shape for the content. Gifting three amounts is *one* decision
/// with three values, not three peer actions, and a flat menu gave a Yolk amount the same
/// visual weight as "see everything they own".
struct FriendActionsSheet: View {
    let friend: Friend
    let giftAmounts: [Int]
    var busy: Bool = false

    var onSeeCollection: () -> Void
    var onSwap: () -> Void
    var onGift: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.md) {
            Text(friend.displayName)
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
                .padding(.top, YolkSpace.md)

            VStack(spacing: YolkSpace.sm) {
                // Seeing what they have comes FIRST. It is what makes a swap worth
                // proposing, and offering one blind is how you waste both people's time.
                row(.cards, "see what they've found",
                    detail: (friend.found?.count).map { "\($0) found" }) {
                    dismiss(); onSeeCollection()
                }
                row(.swap, "offer a swap",
                    detail: "they have to say yes") {
                    dismiss(); onSwap()
                }
            }

            Divider().overlay(YolkColor.line)

            VStack(alignment: .leading, spacing: YolkSpace.sm) {
                HStack(spacing: 7) {
                    YolkGlyph(kind: .gift, size: 15)
                    Text("gift \(Currency.name.lowercased())")
                        .font(YolkType.bodySmall.weight(.semibold))
                }
                .foregroundStyle(YolkColor.inkSoft)

                // One decision with three values, so they sit on one line as a choice
                // rather than stacking as three separate actions.
                HStack(spacing: YolkSpace.sm) {
                    ForEach(giftAmounts, id: \.self) { amount in
                        Button {
                            dismiss()
                            onGift(amount)
                        } label: {
                            Text("\(amount)")
                                .font(YolkType.body.weight(.bold))
                                .foregroundStyle(YolkColor.ink)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(YolkColor.shell2, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(busy)
                    }
                }
                Text("it comes out of your own \(Currency.name.lowercased()). that's the point.")
                    .font(.caption2).foregroundStyle(YolkColor.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, YolkSpace.lg)
        .padding(.bottom, YolkSpace.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(YolkColor.shell)
    }

    private func row(_ glyph: YolkGlyph.Kind, _ title: String,
                     detail: String?, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.select()
            action()
        } label: {
            HStack(spacing: YolkSpace.sm) {
                YolkGlyph(kind: glyph, size: 19)
                    .foregroundStyle(YolkColor.ink)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(YolkType.body.weight(.semibold))
                        .foregroundStyle(YolkColor.ink)
                    if let detail {
                        Text(detail).font(.caption2).foregroundStyle(YolkColor.muted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(YolkColor.muted)
            }
            .padding(.horizontal, YolkSpace.md).padding(.vertical, 13)
            .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

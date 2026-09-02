import SwiftUI
import YolklingCore

/// Explains where Yolks come from, in the one place somebody is thinking about spending.
///
/// **Why this exists.** The Shop dimmed the price of anything you could not afford and
/// said nothing else: no hint of how to get more, no mention that Yolks cannot be bought,
/// and no sign that Yolkling Plus existed. Plus had exactly one entry point in the whole
/// app, a row buried in Profile that nobody has a reason to open. Somebody who actively
/// WANTED to give us money could not find out how, and somebody short of Yolks could not
/// find out what to do about it. Both are answered here.
///
/// **It leads with the refusal, not the offer.** "earned, never bought" is the first line
/// because it is the most surprising true thing about this shop and the whole reason the
/// economy is worth trusting. Putting the subscription first would make it read like a
/// currency upsell, which is the exact thing it is not: there is no code path anywhere in
/// the app that sells Yolks, at any price.
///
/// The Plus line is deliberately quiet and factual. It names what you get and does not
/// argue for it.
struct YolksExplainer: View {
    var onOpenPlus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            HStack(spacing: 8) {
                YolkCoin(size: 16, animated: false)
                Text("Yolks are earned, never bought")
                    .font(YolkType.body.weight(.semibold))
                    .foregroundStyle(YolkColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("check in, walk, sleep, and take time off your phone. that is the only way to get them, and there is no way to buy them at any price.")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(YolkColor.line)

            Button(action: onOpenPlus) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("yolkling+")
                            .font(YolkType.body.weight(.semibold))
                            .foregroundStyle(YolkColor.ink)
                        Text("a supporter glow and 400 Yolks a month. everything here is reachable without it.")
                            .font(YolkType.bodySmall)
                            .foregroundStyle(YolkColor.muted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(YolkColor.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(YolkSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(YolkColor.line, lineWidth: 1))
    }
}

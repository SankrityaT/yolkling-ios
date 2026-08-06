import SwiftUI

/// The Yolkling+ paywall. Free play is never gated — this is the supporter tier
/// ("only if you love it, it keeps the servers on"). Clear price, restore, and
/// terms/privacy, per App Store guidelines.
struct PlusView: View {
    @State var store: SubscriptionStore
    var vibe: Vibe = .yolk

    @Environment(\.dismiss) private var dismiss
    @State private var dialog: YolkDialog?

    /// Only things that actually ship.
    ///
    /// This list previously advertised five features, **none of which were built** —
    /// cloud backup, a supporter glow, seasonal species, multiple creatures. Selling
    /// unimplemented functionality is an App Store Guideline 3.1.2 rejection, and it's a
    /// straightforward lie to the person paying. Anything added back here has to exist
    /// first. See docs/CLAIMS.md.
    private let perks: [(String, String)] = [
        ("sparkles",   "a supporter glow on your yolk, so it's visibly yours"),
        ("leaf.fill",  "a monthly handful of Yolks, on the house"),
        ("heart.fill", "you keep this whole thing alive. no ads, ever"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: YolkSpace.lg) {
                    YolklingView(vibe: vibe, expression: .happy, size: 120).frame(height: 150)
                    // The real guard against shipping a Test Store key: it shows up in
                    // TestFlight and in App Review, where a human will see it. An
                    // `assert` cannot do this job — it's compiled out in release.
                    if RevenueCatConfig.isTestStore {
                        Text("TEST STORE — purchases here are simulated, not real")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0xE05A6E), in: RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(spacing: 6) {
                        Text("yolkling+").font(YolkType.title).foregroundStyle(YolkColor.ink)
                        Text("free to hatch, always. this is just for when you love it.")
                            .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                            .multilineTextAlignment(.center)
                    }
                    VStack(alignment: .leading, spacing: YolkSpace.md) {
                        ForEach(perks, id: \.1) { perk in
                            HStack(alignment: .top, spacing: YolkSpace.md) {
                                Image(systemName: perk.0).font(.title3).foregroundStyle(YolkColor.yolkDeep).frame(width: 30)
                                Text(perk.1).font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, YolkSpace.sm)
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.top, YolkSpace.md)
            }
            footer
        }
        .background(YolkColor.shell)
        .yolkDialog($dialog)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft).padding(10).background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg).padding(.top, YolkSpace.sm)
    }

    @ViewBuilder private var footer: some View {
        VStack(spacing: YolkSpace.sm) {
            if store.isPlus {
                Text("you're a supporter ♥ thank you, truly.")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    .padding(.vertical, 14)
            } else {
                Button { subscribe() } label: {
                    VStack(spacing: 2) {
                        Text(store.purchasing ? "…" : "become a supporter").font(YolkType.body.weight(.semibold))
                        Text("\(store.priceText) / month · cancel anytime").font(.caption2).opacity(0.9)
                    }
                    .foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(store.purchasing)
            }
            HStack(spacing: YolkSpace.md) {
                Button("restore") { Task { await store.restore() } }
                Link("terms", destination: URL(string: "https://yolkling.com/terms")!)
                Link("privacy", destination: URL(string: "https://yolkling.com/privacy")!)
            }
            .font(.caption2).foregroundStyle(YolkColor.muted)
        }
        .padding(.horizontal, YolkSpace.lg).padding(.vertical, YolkSpace.md)
        .background(YolkColor.shell)
    }

    private func subscribe() {
        Task {
            let ok = await store.subscribe()
            if ok {
                Haptics.shared.reward()
                dialog = YolkDialog(icon: .creature(vibe, .affectionate), title: "you're a supporter!",
                                    message: "thank you for keeping yolkling alive. it means everything.", primaryTitle: "♥")
            }
        }
    }
}

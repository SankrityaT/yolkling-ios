import SwiftUI
import YolklingCore

/// Swapping cosmetics with a friend.
///
/// Two halves: offers waiting on you, and a way to make one. Both are deliberately plain
/// — a trade is a small favour between friends, not a marketplace, so there's no browsing,
/// no history, no valuations, and nothing that would make it feel like a floor.
///
/// The picker only ever shows swaps that can SUCCEED: things you own that they don't,
/// against things they own that you don't. Without that this would be a guessing game
/// where you find out the offer was impossible only after the server refuses it.
struct TradeSheet: View {
    @State var store: SocialStore
    /// nil → just the inbox. Set → also offer a swap with this friend.
    var friend: Friend? = nil
    let vibe: Vibe
    /// The live wallet. Required, not optional: a swap moves real items, and without this
    /// the id you gave away stays in `owned` and `HomeView.persist()` re-inserts it via
    /// `push_wallet` — so both players end up owning it. An optional here would fail
    /// silently, which is exactly the bug being fixed.
    let wallet: Wallet
    /// What YOUR yolkling is wearing, so every swap can be previewed on the creature you
    /// actually own rather than on a bare stand-in.
    var myOutfit: [Cosmetic] = []

    @Environment(\.dismiss) private var dismiss
    @State private var mine: [Cosmetic] = []
    @State private var theirs: [Cosmetic] = []
    @State private var give: Cosmetic?
    @State private var want: Cosmetic?
    @State private var busy = false
    @State private var dialog: YolkDialog?
    @State private var loading = true

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: YolkSpace.lg) {
                    if !store.incomingTrades.isEmpty { incomingSection }
                    if friend != nil { proposeSection }
                    if store.incomingTrades.isEmpty && friend == nil && !loading { emptyState }
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.bottom, YolkSpace.xl)
            }
        }
        .padding(.top, YolkSpace.md)
        .background(YolkColor.shell)
        .yolkDialog($dialog)
        .task { await load() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("swap").font(YolkType.heading).foregroundStyle(YolkColor.ink)
                Text("trade a spare with a friend")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
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

    // MARK: Offers waiting on you

    private var incomingSection: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            Text("waiting on you").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            ForEach(store.incomingTrades) { offer in
                VStack(spacing: YolkSpace.md) {
                    Text("\(offer.otherName) wants to swap")
                        .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)

                    // Accepting a trade is a decision about your creature, so the answer to
                    // "should I?" is your creature, before and after — not two objects in
                    // boxes you have to mentally dress yourself.
                    SwapPreview(vibe: vibe, currentOutfit: myOutfit,
                                giving: offer.cosmeticYouGive, getting: offer.cosmeticYouGet)

                    // The preview carries the picture; these two lines carry the names and
                    // rarities, which it can't.
                    VStack(spacing: 4) {
                        namedRow(offer.cosmeticYouGet, label: "you get", gaining: true)
                        namedRow(offer.cosmeticYouGive, label: "you give", gaining: false)
                    }

                    HStack(spacing: YolkSpace.sm) {
                        Button { Haptics.shared.tick(); respond(offer, accept: false) } label: {
                            Text("no thanks").font(YolkType.bodySmall.weight(.semibold))
                                .foregroundStyle(YolkColor.inkSoft)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(YolkColor.shell, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        Button { Haptics.shared.select(); respond(offer, accept: true) } label: {
                            Text("swap").font(YolkType.body.weight(.semibold))
                                .foregroundStyle(YolkColor.shell)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(YolkColor.ink, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(YolkSpace.md)
                .background(YolkColor.shell2.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
                .disabled(busy)
            }
        }
    }

    // MARK: Make an offer

    @ViewBuilder private var proposeSection: some View {
        if let friend {
            VStack(alignment: .leading, spacing: YolkSpace.sm) {
                Text("offer \(friend.displayName) a swap")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)

                if mine.isEmpty || theirs.isEmpty {
                    Text(loading ? "looking…" : "nothing to swap yet — you'd both need something the other hasn't got.")
                        .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, YolkSpace.md)
                } else {
                    // The preview sits ABOVE the pickers on purpose. It's the thing the
                    // screen is for; putting it under two scrolling rows would push it off
                    // the fold on a small phone at exactly the moment it becomes useful.
                    SwapPreview(vibe: vibe, currentOutfit: myOutfit, giving: give, getting: want)
                        // The beat where the swap becomes real and the "after" creature
                        // lands. One pop, on the transition only — re-picking within a
                        // complete swap keeps the lighter per-tile ticks.
                        .onChange(of: give != nil && want != nil) { _, complete in
                            if complete { Haptics.shared.pop() }
                        }

                    pickRow(title: "you give", items: mine, selection: $give, gaining: false)
                    pickRow(title: "you get", items: theirs, selection: $want, gaining: true)

                    Button { Haptics.shared.select(); propose(to: friend) } label: {
                        Text(busy ? "asking…" : "ask for the swap")
                            .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(YolkColor.ink.opacity(give != nil && want != nil ? 1 : 0.3), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(give == nil || want == nil || busy)

                    Text("they have to say yes. nothing moves until they do.")
                        .font(.caption2).foregroundStyle(YolkColor.muted)
                }
            }
        }
    }

    private func pickRow(title: String, items: [Cosmetic], selection: Binding<Cosmetic?>, gaining: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(gaining ? Color(hex: 0x5FA86B) : YolkColor.muted)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(
                        (gaining ? Color(hex: 0x5FA86B) : YolkColor.muted).opacity(0.14),
                        in: Capsule()
                    )
                if selection.wrappedValue == nil {
                    Text("pick one").font(.caption2).foregroundStyle(YolkColor.muted)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: YolkSpace.sm) {
                    ForEach(items) { item in
                        let on = selection.wrappedValue?.id == item.id
                        Button {
                            // Picking and un-picking should not feel the same. Choosing is
                            // the crisp one; putting something back is a soft tick.
                            if on { Haptics.shared.tick() } else { Haptics.shared.select() }
                            selection.wrappedValue = on ? nil : item
                        } label: {
                            ItemTile(item: item, vibe: vibe, side: 96, selected: on)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 10)
            }
        }
    }

    /// Name + rarity for one side of an incoming offer. The `SwapPreview` above it already
    /// shows what the trade looks like; this only has to say what the things are called.
    private func namedRow(_ item: Cosmetic?, label: String, gaining: Bool) -> some View {
        let accent = gaining ? Color(hex: 0x5FA86B) : YolkColor.muted
        return HStack(spacing: YolkSpace.sm) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(accent)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(accent.opacity(0.14), in: Capsule())
                // Fixed width so the two labels' trailing edges line up and the names
                // start on a shared left margin.
                .frame(width: 70, alignment: .leading)
            Text(item?.name ?? "something")
                .font(YolkType.bodySmall.weight(.semibold))
                .foregroundStyle(YolkColor.ink)
                .lineLimit(1)
            if let item, item.rarity != .common {
                Text(item.rarity.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(item.rarity == .epic ? Color(hex: 0xFFC23B) : Color(hex: 0x8FD0FF))
            }
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: YolkSpace.sm) {
            YolklingView(vibe: vibe, expression: .curious, size: 110, frozenAt: YolklingView.posedT)
            Text("no swaps right now")
                .font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
            Text("visit a friend to offer one.")
                .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, YolkSpace.xl)
    }

    // MARK: Behaviour

    private func load() async {
        await store.loadTrades()
        if let friend {
            let t = await store.tradeable(with: friend.user_id)
            mine = t.mine; theirs = t.theirs
        }
        loading = false
    }

    private func propose(to friend: Friend) {
        guard let give, let want else { return }
        busy = true
        Task {
            let r = await store.propose(to: friend.user_id, offer: give.id, want: want.id)
            busy = false
            if r.ok {
                Haptics.shared.reward()
                self.give = nil; self.want = nil
                await load()
                dialog = YolkDialog(icon: .creature(vibe, .happy), title: "asked!",
                                    message: "\(friend.displayName) will see it next time they're around.",
                                    primaryTitle: "nice")
            } else {
                Haptics.shared.warn()
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                    message: reason(r.reason), primaryTitle: "okay")
            }
        }
    }

    private func respond(_ offer: TradeOffer, accept: Bool) {
        busy = true
        Task {
            let r = await store.respond(to: offer, accept: accept)
            busy = false
            if r.ok {
                Haptics.shared.reward()
                if accept {
                    // The server has ALREADY performed this swap — `respond_trade` deleted
                    // both rows and inserted the two new ones. Mirror it locally with the
                    // same two ids the trade row carries, so the next `push_wallet` can't
                    // re-insert what was just given away. No refetch needed: these come
                    // from the row the server acted on, so they cannot disagree with it.
                    //
                    // Mutating `owned` fires HomeView's `.onChange(of: wallet.owned)`,
                    // which prunes the outfit and pushes — no callback required.
                    wallet.applyTrade(gave: offer.youGive, got: offer.youGet)
                    dialog = YolkDialog(icon: .creature(vibe, .excited), title: "swapped!",
                                        message: "\(offer.cosmeticYouGet?.name ?? "it") is yours now.",
                                        primaryTitle: "lovely")
                }
            } else {
                Haptics.shared.warn()
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                    message: reason(r.reason), primaryTitle: "okay")
            }
        }
    }

    private func reason(_ code: String?) -> String {
        switch code {
        case "not_friends":        "you can only swap with friends."
        case "not_tradeable":      "founding species stay with the person who earned them."
        case "you_dont_own_that":  "you don't have that any more."
        case "they_dont_own_that": "they don't have that any more."
        case "already_have":       "you've already got that one."
        case "too_many_pending":   "you've got a few swaps out already. wait on those first."
        case "already_offered":    "you've already asked for that one."
        case "no_longer_held":     "one of you traded it away in the meantime."
        case "expired":            "that offer ran out."
        case "blocked":            "you can't reach them."
        default:                   "couldn't do that just now. try again in a sec."
        }
    }
}

import SwiftUI
import YolklingCore

/// Stand in someone's room: their creature and their decorations, reconstructed from the
/// snapshot they published. You can wave, leave a composed note, or gift Yolks.
///
/// Serves both a friend and a drifted-to stranger — see `VisitSubject`. The room renders
/// identically either way; only the permitted actions differ.
struct VisitView: View {
    let subject: VisitSubject
    @State var store: SocialStore
    let vibe: Vibe
    let wallet: Wallet
    /// Your own outfit, carried through so a swap can be previewed on your creature.
    /// Stranger visits never reach the trade sheet, so it's optional there.
    var myOutfit: [Cosmetic] = []
    /// Species YOU have found, so their collection can mark what is new to you. That
    /// difference is the whole reason to look at somebody else's cards.
    var myDiscovered: Set<String> = []
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var composing = false
    @State private var waved = false
    @State private var theirWaveToken = 0   // bump to make their yolk wave back
    @State private var dialog: YolkDialog?
    @State private var giftBusy = false
    @State private var swapping = false
    @State private var showCollection = false
    @State private var showActions = false
    @State private var showBlock = false
    @State private var showGift = false
    /// Strangers require a successful drift before any action is allowed.
    @State private var landed = false

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            header
            room
                .frame(height: 380)
                .padding(.horizontal, YolkSpace.md)
            caption
            if !subject.isStranger || landed { actionsRow }
            Spacer(minLength: 0)
        }
        .padding(.top, YolkSpace.md)
        .background(YolkColor.shell)
        .sheet(isPresented: $composing) {
            PostcardCompose(subject: subject, store: store, vibe: vibe, onReward: onReward)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $swapping) {
            if case .friend(let f) = subject {
                TradeSheet(store: store, friend: f, vibe: vibe,
                           wallet: wallet, myOutfit: myOutfit)
                    .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showCollection) {
            if case .friend(let f) = subject {
                FriendCollectionView(friend: f, mine: myDiscovered)
                    .presentationDetents([.large])
            }
        }
        // Sits at the bottom of the screen, in the empty space BELOW the action row rather
        // than on top of it. Anchoring near the row looked right on a Pro Max and covered
        // the buttons that opened it; the room shrinks with the screen, so there is no
        // fixed offset above the row that survives an SE. Bottom-anchored is the same on
        // every device, and it still grows out of the button's edge.
        .yolkMenu(isPresented: $showActions, alignment: .bottom, anchor: .top) {
            friendMenu.padding(.bottom, YolkSpace.lg)
        }
        .yolkMenu(isPresented: $showGift, alignment: .bottom, anchor: .top) {
            strangerGiftMenu.padding(.bottom, YolkSpace.lg)
        }
        .yolkMenu(isPresented: $showBlock, alignment: .topTrailing) {
            YolkMenu(width: 230) {
                YolkMenuRow(glyph: nil, title: "block \(subject.displayName)",
                            detail: "your yolklings won't cross paths again",
                            destructive: true) {
                    Haptics.shared.warn()
                    showBlock = false
                    block()
                }
            }
            .padding(.trailing, YolkSpace.lg)
            .padding(.top, 56)
        }
        .yolkDialog($dialog)
        .task { await arrive() }
    }

    /// Landing. For a friend this is just a visit log; for a stranger the drift MUST be
    /// recorded server-side first — every stranger action is refused otherwise, and the
    /// refusal reads as "not_friends", which would be nonsense to the user.
    private func arrive() async {
        switch subject {
        case .friend(let f):
            await store.logVisit(owner: f.user_id)
            landed = true
        case .stranger(let s):
            landed = await store.drift(to: s.user_id)
            if !landed {
                dialog = YolkDialog(
                    icon: .creature(vibe, .sleepy),
                    title: "wandered enough",
                    message: "your yolkling has done its rounds for today. it'll head out again tomorrow.",
                    primaryTitle: "okay", primaryAction: { dismiss() }
                )
            }
        }
    }

    @ViewBuilder private var room: some View {
        if let snap = subject.snapshot {
            RoomView(vibe: snap.makeVibe(name: subject.displayName), expression: snap.expression,
                     theme: snap.theme, outfit: snap.outfit, decor: snap.decor, waveToken: theirWaveToken)
        } else {
            RoomView(vibe: .yolk, expression: .happy, theme: RoomThemes.cozy, waveToken: theirWaveToken)
        }
    }

    private var caption: some View {
        Text(subject.snapshot == nil
             ? "\(subject.displayName) hasn't decorated yet"
             : "\(subject.displayName)'s room")
            .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
    }

    private var header: some View {
        HStack {
            Text(subject.heading).font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Spacer()
            // Guideline 1.2: once a stranger can reach you, blocking has to be reachable
            // from the place you meet them, not buried in settings.
            if subject.isStranger {
                Button {
                    Haptics.shared.tick()
                    withAnimation(.snappy(duration: 0.22)) { showBlock = true }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(YolkColor.inkSoft).padding(10)
                        .background(YolkColor.shell2, in: Circle())
                }
                .buttonStyle(.plain)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft).padding(10).background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg)
    }

    // MARK: Actions

    private var actionsRow: some View {
        HStack(spacing: YolkSpace.sm) {
            waveButton
            noteButton
            // Swapping is friends-only: a stranger offer is a scam surface with no upside,
            // and you've no reason to trust someone your creature met once.
            if case .friend = subject { swapButton } else { giftMenu }
        }
        .padding(.horizontal, YolkSpace.lg)
        .padding(.top, YolkSpace.xs)
    }

    private var waveButton: some View {
        Button {
            guard !waved else { return }
            Haptics.shared.select()
            waved = true
            theirWaveToken += 1
            Task { await store.sendWave(to: subject.userID) }
        } label: {
            actionLabel(.wave, waved ? "waved!" : "wave", filled: false)
                .foregroundStyle(waved ? YolkColor.muted : YolkColor.ink)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: waved)
    }

    private var noteButton: some View {
        Button { composing = true } label: {
            actionLabel(.note, "leave a note", filled: true)
        }
        .buttonStyle(.plain)
    }

    /// What you can do in a friend's room, in our own menu rather than a native one.
    ///
    /// Seeing what they have comes FIRST: it is what makes a swap worth proposing, and
    /// offering one blind wastes both people's time.
    ///
    /// The gift amounts are one row of three, not three rows. Gifting is ONE decision with
    /// three values, and a flat list gave a Yolk amount the same weight as "see everything
    /// they own".
    @ViewBuilder private var friendMenu: some View {
        if case .friend(let f) = subject {
            YolkMenu {
                YolkMenuRow(glyph: .cards, title: "see what they've found",
                            detail: (f.found?.count).map { "\($0) found" }) {
                    Haptics.shared.select()
                    showActions = false
                    showCollection = true
                }
                YolkMenuDivider()
                YolkMenuRow(glyph: .swap, title: "offer a swap",
                            detail: "they have to say yes") {
                    Haptics.shared.select()
                    showActions = false
                    swapping = true
                }
                YolkMenuDivider()

                VStack(alignment: .leading, spacing: YolkSpace.sm) {
                    HStack(spacing: 7) {
                        YolkGlyph(kind: .gift, size: 15)
                        Text("gift \(Currency.name.lowercased())")
                            .font(YolkType.bodySmall.weight(.semibold))
                    }
                    .foregroundStyle(YolkColor.inkSoft)

                    HStack(spacing: YolkSpace.sm) {
                        ForEach(subject.giftAmounts, id: \.self) { amount in
                            Button {
                                Haptics.shared.select()
                                showActions = false
                                sendGift(amount)
                            } label: {
                                Text("\(amount)")
                                    .font(YolkType.body.weight(.bold))
                                    .foregroundStyle(YolkColor.ink)
                                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                                    .background(YolkColor.shell2, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(giftBusy)
                        }
                    }
                    Text("it comes out of your own \(Currency.name.lowercased()).")
                        .font(.caption2).foregroundStyle(YolkColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, YolkSpace.md)
                .padding(.vertical, 12)
            }
        }
    }

    /// Opens the drawn menu. See `friendMenu`.
    private var swapButton: some View {
        Button {
            Haptics.shared.tick()
            withAnimation(.snappy(duration: 0.24)) { showActions = true }
        } label: {
            actionLabel(.swap, giftBusy ? "..." : "swap", filled: false)
                .foregroundStyle(YolkColor.ink)
        }
        .buttonStyle(.plain)
        .disabled(giftBusy)
    }

    private var giftMenu: some View {
        Button {
            Haptics.shared.tick()
            withAnimation(.snappy(duration: 0.24)) { showGift = true }
        } label: {
            actionLabel(.gift, giftBusy ? "..." : "gift", filled: false)
                .foregroundStyle(YolkColor.ink)
        }
        .buttonStyle(.plain)
        .disabled(giftBusy)
    }

    /// A stranger gets one fixed amount, once a day, so this is one row rather than three.
    private var strangerGiftMenu: some View {
        YolkMenu(width: 250) {
            ForEach(subject.giftAmounts, id: \.self) { amount in
                YolkMenuRow(glyph: .gift, title: "gift \(amount) \(Currency.name.lowercased())",
                            detail: "it comes out of your own") {
                    Haptics.shared.select()
                    showGift = false
                    sendGift(amount)
                }
            }
        }
    }

    /// Drawn glyphs, not emoji.
    ///
    /// This row used 👋 💌 🔁 🎁. The swap emoji renders BLUE on iOS, which is not in this
    /// app's palette at all, and all four came from a different rendering engine than
    /// everything else on the screen. In an app whose whole claim is that nothing is an
    /// asset, the action row was four imported pictures.
    ///
    /// The glyph strokes with `.foreground`, so it simply inherits the label's colour and
    /// the filled variant needs no special handling.
    private func actionLabel(_ glyph: YolkGlyph.Kind, _ title: String, filled: Bool) -> some View {
        HStack(spacing: 7) {
            YolkGlyph(kind: glyph, size: 16)
            Text(title).font(YolkType.bodySmall.weight(.semibold))
        }
        .foregroundStyle(filled ? YolkColor.shell : YolkColor.ink)
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(filled ? YolkColor.ink : YolkColor.shell2, in: Capsule())
    }

    // MARK: Behaviour

    private func block() {
        Task {
            let ok = await store.block(subject.userID)
            Haptics.shared.warn()
            dialog = YolkDialog(
                icon: .creature(vibe, .curious),
                title: ok ? "blocked" : "hmm",
                message: ok
                    ? "your yolklings won't cross paths again."
                    : "couldn't do that just now. try again in a sec.",
                primaryTitle: "okay", primaryAction: { if ok { dismiss() } }
            )
        }
    }

    private func sendGift(_ amount: Int) {
        giftBusy = true
        Task {
            let result = await store.giftYolks(to: subject.userID, amount: amount)
            giftBusy = false
            if result.ok {
                Haptics.shared.reward()
                if let newCoins = result.coins { wallet.adopt(coins: newCoins, owned: wallet.owned) }
                dialog = YolkDialog(
                    icon: .coins, title: "gifted!",
                    message: "you sent \(amount) \(Currency.name) to \(subject.displayName). how kind.",
                    primaryTitle: "lovely"
                )
            } else {
                Haptics.shared.warn()
                let message: String
                switch result.reason {
                case "insufficient":        message = "you don't have enough \(Currency.name) for that."
                case "daily_cap":           message = "you have hit today's gift limit. come back tomorrow."
                case "stranger_gift_cap":   message = "one gift to a stranger a day. it means more that way."
                case "stranger_amount":     message = "a stranger gets a small gift — that's the whole idea."
                case "blocked":             message = "you can't reach them."
                case "not_friends":         message = "your yolkling isn't there any more."
                default:                    message = "couldn't send that just now. try again in a sec."
                }
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                    message: message, primaryTitle: "okay")
            }
        }
    }
}

import SwiftUI
import YolklingCore

/// The friends surface: see each friend's living room, catch up on what happened
/// while you were away, wave, visit, and grow your circle. No likes, no followers,
/// no feed (docs/GAME.md). The referral code doubles as the friend code.
struct FriendsView: View {
    @State var store: SocialStore
    let vibe: Vibe
    let player: Player?
    let myName: String
    let mySnapshot: RoomSnapshot
    let wallet: Wallet
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var dialog: YolkDialog?
    @State private var visiting: Friend?
    @State private var showInbox = false
    @State private var showInvite = false
    /// The swap inbox. TradeSheet has always supported being opened with no friend
    /// ("just the inbox"), but nothing ever opened it that way, so an offer sent to you was
    /// only visible if you happened to start a swap of your own within three days.
    @State private var showSwaps = false

    // Living-tab state
    @State private var waves: [Wave] = []
    @State private var visits: [Visit] = []

    // MARK: - Computed

    /// Friends whose room was updated after we last visited them.
    private var redecorated: [Friend] {
        store.friends.filter { f in
            let lv = store.lastVisited(f.user_id)
            if let u = f.updatedDate {
                return lv == nil || u > lv!
            }
            return false
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: YolkSpace.md) {
                    // Swaps waiting on you, first, because they expire.
                    if !store.incomingTrades.isEmpty { swapsWaiting }

                    // "While you were away" strip (hidden when nothing to show)
                    WhileYouWereAwayStrip(
                        waves: waves,
                        visits: visits,
                        redecorated: redecorated,
                        onTap: { id in
                            visiting = store.friends.first { $0.user_id == id }
                        }
                    )

                    // Friends grid or empty state
                    if store.friends.isEmpty {
                        emptyState
                    } else {
                        friendsGrid
                    }

                    // Grow section: add by code, share, QR, scan, invite
                    GrowFriendsView(
                        store: store,
                        myCode: store.myCode,
                        vibe: vibe,
                        onAdded: { Task { await store.load() } },
                        dialog: $dialog
                    )
                    .padding(.horizontal, YolkSpace.lg)
                    .padding(.bottom, YolkSpace.lg)
                }
                .padding(.top, YolkSpace.sm)
            }
            // Marks this as the scroll that decides whether a downward drag is a scroll
            // or a dismiss. Without it, swipeToDismiss closes the screen when somebody
            // scrolls back up. See SwipeToDismiss.swift.
            .dismissAwareScroll()
        }
        .background(YolkColor.shell)
        .swipeToDismiss()
        .yolkDialog($dialog)
        .sheet(item: $visiting) { f in
            VisitView(subject: .friend(f), store: store, vibe: vibe, wallet: wallet,
                      myOutfit: mySnapshot.outfit,
                      myDiscovered: Set(player?.discoveredSpeciesIDs ?? []),
                      onReward: onReward)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInbox) {
            PostcardInbox(store: store).presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSwaps, onDismiss: { Task { await store.loadTrades() } }) {
            TradeSheet(store: store, vibe: vibe, wallet: wallet, myOutfit: mySnapshot.outfit)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInvite) {
            ReferralView(vibe: vibe, player: player) { onReward($0) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await store.ensureCode()
            await store.publish(name: myName, snapshot: mySnapshot)
            await store.load()
            async let w = store.loadWaves()
            async let v = store.loadRecentVisits()
            async let t: Void = store.loadTrades()
            let (loadedWaves, loadedVisits, _) = await (w, v, t)
            waves = loadedWaves
            visits = loadedVisits
        }
    }

    // MARK: - Swaps waiting

    /// Offers other people have sent you.
    ///
    /// Until 1.0.1 there was no way to see these. Offers were loaded only inside the swap
    /// screen, and that screen was only reachable by starting a swap of your own from a
    /// friend's room. So the person on the receiving end was never told, and an offer
    /// expired unseen after three days. Trading worked mechanically and almost never
    /// happened socially.
    private var swapsWaiting: some View {
        let offers = store.incomingTrades
        let title = offers.count == 1
            ? "\(offers[0].otherName) wants to swap"
            : "\(offers.count) swaps waiting on you"
        return Button {
            Haptics.shared.tick()
            showSwaps = true
        } label: {
            HStack(spacing: YolkSpace.sm) {
                YolkGlyph(kind: .swap, size: 20, weight: 0.1)
                    .foregroundStyle(YolkColor.ink)
                    .frame(width: 40, height: 40)
                    .background(YolkColor.yolk.opacity(0.35), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(YolkType.body.weight(.semibold))
                        .foregroundStyle(YolkColor.ink)
                    Text("offers expire after three days")
                        .font(YolkType.bodySmall)
                        .foregroundStyle(YolkColor.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft)
            }
            .padding(YolkSpace.md)
            .background(YolkColor.shell2.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, YolkSpace.lg)
        .accessibilityHint("opens the offers other people have sent you")
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            YolkCloseButton { dismiss() }
            Text("friends").font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Spacer()
            Button { showInbox = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "envelope.fill").font(.system(size: 18))
                        .foregroundStyle(YolkColor.inkSoft)
                        .padding(10).background(YolkColor.shell2, in: Circle())
                    if store.unreadCount > 0 {
                        Text("\(store.unreadCount)").font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white).padding(5).background(YolkColor.pink, in: Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg).padding(.vertical, YolkSpace.sm)
    }

    // MARK: - Friends grid

    private let gridColumns = [
        GridItem(.flexible(), spacing: YolkSpace.sm),
        GridItem(.flexible(), spacing: YolkSpace.sm)
    ]

    private var friendsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: YolkSpace.sm) {
            ForEach(store.friends) { friend in
                FriendRoomCard(friend: friend, store: store) { f in
                    visiting = f
                }
            }
        }
        .padding(.horizontal, YolkSpace.lg)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: YolkSpace.sm) {
            // A failed load is NOT an empty friends list. This screen used to show the
            // brand-new-user copy ("no friends yet") to somebody with friends whenever a
            // request dropped, which reads as data loss.
            Text(store.loadFailed ? "couldn't reach your friends" : "no friends yet")
                .font(YolkType.body.weight(.semibold))
                .foregroundStyle(YolkColor.inkSoft)
            Text(store.loadFailed
                 ? "your friends are still there. we just couldn't reach them. check your connection and reopen this tab."
                 : "add someone with their code or share yours below.")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, YolkSpace.lg)
        .padding(.horizontal, YolkSpace.lg)
    }
}

import SwiftUI

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
                        onAdded: { Task { await store.load() } }
                    )
                    .padding(.horizontal, YolkSpace.lg)
                    .padding(.bottom, YolkSpace.lg)
                }
                .padding(.top, YolkSpace.sm)
            }
        }
        .background(YolkColor.shell)
        .yolkDialog($dialog)
        .sheet(item: $visiting) { f in
            VisitView(friend: f, store: store, vibe: vibe, wallet: wallet, onReward: onReward)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showInbox) {
            PostcardInbox(store: store).presentationDetents([.large])
        }
        .sheet(isPresented: $showInvite) {
            ReferralView(vibe: vibe, player: player) { onReward($0) }
                .presentationDetents([.large])
        }
        .task {
            await store.ensureCode()
            await store.publish(name: myName, snapshot: mySnapshot)
            await store.load()
            async let w = store.loadWaves()
            async let v = store.loadRecentVisits()
            let (loadedWaves, loadedVisits) = await (w, v)
            waves = loadedWaves
            visits = loadedVisits
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
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
            Text("no friends yet")
                .font(YolkType.body.weight(.semibold))
                .foregroundStyle(YolkColor.inkSoft)
            Text("add someone with their code or share yours below.")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, YolkSpace.lg)
        .padding(.horizontal, YolkSpace.lg)
    }
}

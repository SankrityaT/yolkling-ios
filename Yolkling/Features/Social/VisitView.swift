import SwiftUI

/// Visit a friend's pet house: their creature in their decorated room, reconstructed
/// from the snapshot they published. You can wave, leave a kind note, or gift yolks.
struct VisitView: View {
    let friend: Friend
    @State var store: SocialStore
    let vibe: Vibe
    let wallet: Wallet
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var composing = false
    @State private var waved = false
    @State private var friendWaveToken = 0   // bump to make the friend's yolk wave back
    @State private var dialog: YolkDialog?
    @State private var giftBusy = false

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            header
            room
                .frame(height: 380)
                .padding(.horizontal, YolkSpace.md)
            Text(friend.snapshot == nil ? "\(friend.displayName) hasn't decorated yet" : "\(friend.displayName)'s room")
                .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            actionsRow
            Spacer(minLength: 0)
        }
        .padding(.top, YolkSpace.md)
        .background(YolkColor.shell)
        .sheet(isPresented: $composing) {
            PostcardCompose(friend: friend, store: store, vibe: vibe, onReward: onReward)
                .presentationDetents([.medium, .large])
        }
        .yolkDialog($dialog)
        .task { await store.logVisit(owner: friend.user_id) }
    }

    @ViewBuilder private var room: some View {
        if let snap = friend.snapshot {
            RoomView(vibe: snap.makeVibe(name: friend.displayName), expression: snap.expression,
                     theme: snap.theme, outfit: snap.outfit, decor: snap.decor, waveToken: friendWaveToken)
        } else {
            RoomView(vibe: .yolk, expression: .happy, theme: RoomThemes.cozy, waveToken: friendWaveToken)
        }
    }

    private var header: some View {
        HStack {
            Text("visiting").font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft).padding(10).background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg)
    }

    // MARK: Actions row

    private var actionsRow: some View {
        HStack(spacing: YolkSpace.sm) {
            waveButton
            noteButton
            giftMenu
        }
        .padding(.horizontal, YolkSpace.lg)
        .padding(.top, YolkSpace.xs)
    }

    private var waveButton: some View {
        Button {
            guard !waved else { return }
            Haptics.shared.select()
            waved = true
            friendWaveToken += 1   // their yolk waves back
            Task { await store.sendWave(to: friend.user_id) }
        } label: {
            HStack(spacing: 6) {
                Text("👋").font(.system(size: 15))
                Text(waved ? "waved!" : "wave").font(YolkType.bodySmall.weight(.semibold))
            }
            .foregroundStyle(waved ? YolkColor.muted : YolkColor.ink)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(YolkColor.shell2, in: Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: waved)
    }

    private var noteButton: some View {
        Button { composing = true } label: {
            HStack(spacing: 6) {
                Text("💌").font(.system(size: 15))
                Text("leave a note").font(YolkType.bodySmall.weight(.semibold))
            }
            .foregroundStyle(YolkColor.shell)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(YolkColor.ink, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var giftMenu: some View {
        Menu {
            ForEach([10, 20, 50], id: \.self) { amount in
                Button("\(amount) Yolks") { sendGift(amount) }
            }
        } label: {
            HStack(spacing: 6) {
                Text("🎁").font(.system(size: 15))
                Text(giftBusy ? "..." : "gift").font(YolkType.bodySmall.weight(.semibold))
            }
            .foregroundStyle(YolkColor.ink)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(YolkColor.shell2, in: Capsule())
        }
        .disabled(giftBusy)
    }

    private func sendGift(_ amount: Int) {
        giftBusy = true
        Task {
            let result = await store.giftYolks(to: friend.user_id, amount: amount)
            giftBusy = false
            if result.ok {
                Haptics.shared.reward()
                if let newCoins = result.coins {
                    wallet.adopt(coins: newCoins, owned: wallet.owned)
                }
                dialog = YolkDialog(
                    icon: .coins,
                    title: "gifted!",
                    message: "you sent \(amount) Yolks to \(friend.displayName). how kind.",
                    primaryTitle: "lovely"
                )
            } else {
                Haptics.shared.warn()
                let message: String
                switch result.reason {
                case "insufficient":  message = "you don't have enough Yolks for that."
                case "daily_cap":     message = "you have hit today's gift limit. come back tomorrow."
                case "not_friends":   message = "you need to be friends to gift Yolks."
                default:              message = "couldn't send that just now. try again in a sec."
                }
                dialog = YolkDialog(
                    icon: .creature(vibe, .curious),
                    title: "hmm",
                    message: message,
                    primaryTitle: "okay"
                )
            }
        }
    }
}

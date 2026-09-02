import SwiftUI
import YolklingCore

/// Where your yolkling could wander today.
///
/// Deliberately NOT a browse feed: at most three rooms, once a day, no names you can
/// search, no way back to someone you didn't pick. The scarcity is the point — this is
/// a small daily ritual, not a place to spend time.
struct DriftSheet: View {
    @State var store: SocialStore
    let vibe: Vibe
    let myName: String
    let mySnapshot: RoomSnapshot
    let wallet: Wallet
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var loading = true
    @State private var visiting: DriftTarget?
    @State private var opening = false
    @State private var openFailed = false

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            header

            if !store.roomIsPublic {
                openUpPrompt
            } else if loading {
                Spacer()
                ProgressView().tint(YolkColor.muted)
                Spacer()
            } else if store.driftTargets.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: YolkSpace.md) {
                        ForEach(store.driftTargets) { target in
                            roomCard(target)
                        }
                    }
                    .padding(.horizontal, YolkSpace.lg)
                }
            }
        }
        .padding(.top, YolkSpace.md)
        .background(YolkColor.shell)
        .task { await refresh() }
        .sheet(item: $visiting) { t in
            VisitView(subject: .stranger(t), store: store, vibe: vibe,
                      wallet: wallet, myOutfit: mySnapshot.outfit, onReward: onReward)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("wander").font(YolkType.heading).foregroundStyle(YolkColor.ink)
                Text("somewhere new, once a day")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft).padding(10)
                    .background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg)
    }

    /// Rooms are private until their owner says otherwise, so this asks plainly rather
    /// than opting anyone in quietly.
    private var openUpPrompt: some View {
        VStack(spacing: YolkSpace.md) {
            Spacer()
            YolklingView(vibe: vibe, expression: .curious, size: 130, frozenAt: YolklingView.posedT)
            Text("open your door?")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("your yolkling can only wander into rooms that are open. open yours and it can go exploring, and someone else's might drop by.")
                .font(YolkType.body).foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, YolkSpace.lg)
                .fixedSize(horizontal: false, vertical: true)
            Text("no names, no chat. just a room and a kind note.")
                .font(.caption2).foregroundStyle(YolkColor.muted)

            Button { openUp() } label: {
                Text(opening ? "opening…" : "open my door")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(opening)
            .padding(.horizontal, YolkSpace.lg)

            if openFailed {
                Text("couldn't reach the server. your door is still closed. try again in a moment.")
                    .font(.caption2).foregroundStyle(YolkColor.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, YolkSpace.lg)
                    .transition(.opacity)
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: YolkSpace.sm) {
            YolklingView(vibe: vibe, expression: .sleepy, size: 120, frozenAt: YolklingView.posedT)
            Text("nowhere to go today")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("your yolkling has done its rounds. it'll head out again tomorrow.")
                .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, YolkSpace.xl)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func roomCard(_ target: DriftTarget) -> some View {
        Button { Haptics.shared.select(); visiting = target } label: {
            VStack(spacing: 0) {
                if let snap = target.snapshot {
                    RoomView(vibe: snap.makeVibe(name: target.displayName), expression: snap.expression,
                             theme: snap.theme, outfit: snap.outfit, decor: snap.decor)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                Text("a door left open")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                    .padding(.top, YolkSpace.xs)
            }
        }
        .buttonStyle(.plain)
    }

    private func refresh() async {
        guard store.roomIsPublic else { loading = false; return }
        loading = true
        await store.loadDrift()
        loading = false
    }

    private func openUp() {
        opening = true
        Task {
            // Branch on the server's answer. This used to celebrate and PERSIST
            // roomIsPublic = true regardless: reward haptic, prompt gone for good, and
            // the door never actually opened — the only symptom was a forever-empty
            // wander list. Now failure leaves the prompt in place so it can be retried.
            let ok = await store.publish(name: myName, snapshot: mySnapshot, isPublic: true)
            opening = false
            if ok {
                store.roomIsPublic = true
                Haptics.shared.reward()
                await refresh()
            } else {
                Haptics.shared.warn()
                openFailed = true
            }
        }
    }
}

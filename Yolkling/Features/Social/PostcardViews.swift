import SwiftUI

/// Compose a kind note to a friend. A few warm presets to tap, or write your own.
/// The reward (if any) is small, sender-only and server-capped (docs/REWARDS.md).
struct PostcardCompose: View {
    let friend: Friend
    @State var store: SocialStore
    let vibe: Vibe
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var sending = false
    @State private var dialog: YolkDialog?

    private let presets = [
        "thinking of you",
        "your room looks so cozy",
        "hope your day is gentle",
        "you've got this",
        "sending a little sunshine",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.md) {
            Text("a kind note to \(friend.displayName)")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)

            FlowChips(items: presets) { text = $0; Haptics.shared.tick() }

            TextField("write something warm…", text: $text, axis: .vertical)
                .font(YolkType.body).foregroundStyle(YolkColor.ink)
                .lineLimit(3, reservesSpace: true)
                .padding(14).background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))

            Button { send() } label: {
                Text(sending ? "sending…" : "send note")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(YolkColor.ink.opacity(canSend ? 1 : 0.3), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSend || sending)

            Text("kindness earns a few Yolks, capped so it stays genuine.")
                .font(.caption2).foregroundStyle(YolkColor.muted)
            Spacer(minLength: 0)
        }
        .padding(YolkSpace.lg)
        .background(YolkColor.shell)
        .yolkDialog($dialog)
    }

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty }

    private func send() {
        let msg = text.trimmingCharacters(in: .whitespaces)
        guard !msg.isEmpty else { return }
        sending = true
        Task {
            let r = await store.sendPostcard(to: friend.user_id, message: msg)
            sending = false
            if r.ok {
                Haptics.shared.reward()
                if r.reward > 0 { onReward(r.reward) }
                let m = r.reward > 0
                    ? "your note is on its way. +\(r.reward) \(Currency.name) for the kindness."
                    : "your note is on its way. \(friend.displayName) will love it."
                dialog = YolkDialog(icon: .creature(vibe, .affectionate), title: "sent!", message: m,
                                    primaryTitle: "warm", primaryAction: { dismiss() })
            } else {
                Haptics.shared.warn()
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                    message: "couldn't send that just now. try again in a sec.", primaryTitle: "okay")
            }
        }
    }
}

/// The received kind notes. Marked read on open.
struct PostcardInbox: View {
    @State var store: SocialStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("kind notes").font(YolkType.heading).foregroundStyle(YolkColor.ink)
                Spacer()
            }
            .padding(.horizontal, YolkSpace.lg).padding(.vertical, YolkSpace.sm)

            if store.inbox.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "envelope.open").font(.system(size: 34)).foregroundStyle(YolkColor.muted)
                    Text("no notes yet").font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
                    Text("visit a friend and leave one first.").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: YolkSpace.sm) {
                        ForEach(store.inbox) { card in row(card) }
                    }
                    .padding(.horizontal, YolkSpace.lg).padding(.top, YolkSpace.sm)
                }
            }
        }
        .background(YolkColor.shell)
        .task { await store.markInboxRead() }
    }

    private func row(_ card: Postcard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.senderName).font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                Spacer()
                if !card.read { Circle().fill(YolkColor.pink).frame(width: 8, height: 8) }
            }
            Text(card.message).font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(YolkSpace.md)
        .background(YolkColor.shell2.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
    }
}

/// A simple wrapping row of tappable preset chips.
private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button { onTap(item) } label: {
                            Text(item).font(YolkType.bodySmall).foregroundStyle(YolkColor.inkSoft)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(YolkColor.shell2, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // naive 2-per-row layout (preset count is small + fixed)
    private var rows: [[String]] { stride(from: 0, to: items.count, by: 2).map { Array(items[$0..<min($0 + 2, items.count)]) } }
}

import SwiftUI
import YolklingCore

/// Compose a kind note to a friend by PICKING what your yolkling says — there is no
/// free-text field, by design. See `PostcardVocabulary` for the reasoning.
/// The reward (if any) is small, sender-only and server-capped (docs/REWARDS.md).
struct PostcardCompose: View {
    let subject: VisitSubject
    @State var store: SocialStore
    let vibe: Vibe
    let onReward: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    /// The chosen phrase. A TOKEN, not text — the server looks it up and stores its own
    /// copy, so what lands can never be something the client made up.
    @State private var phrase: PostcardVocabulary.Phrase?
    @State private var category: PostcardVocabulary.Category = .warmth
    @State private var sending = false
    @State private var dialog: YolkDialog?

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.md) {
            Text("a kind note to \(subject.displayName)")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)

            // `YolkSegmented`, not `.pickerStyle(.segmented)`. That is a project rule
            // (see the type's own doc comment) and this was one of two places still
            // breaking it. It also fires its own haptic, so the `onChange` went with it.
            YolkSegmented(selection: $category,
                          options: PostcardVocabulary.Category.allCases,
                          label: \.title)

            // GROWS with the sheet. This was pinned to 200pt, so dragging to `.large`
            // gained half a screen of nothing: the phrase list stayed a 200pt letterbox
            // with its top and bottom rows clipped mid-pill, and everything under it
            // floated up leaving a huge dead area. The list is the content — it should
            // take whatever room there is.
            ScrollView(.vertical, showsIndicators: false) {
                FlowChips(items: PostcardVocabulary.phrases(in: category).map(\.text)) { picked in
                    phrase = PostcardVocabulary.phrases(in: category).first { $0.text == picked }
                    Haptics.shared.tick()
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: .infinity)

            // What's actually going to be sent. Read-only on purpose.
            Text(phrase?.text ?? "pick something to say…")
                .font(YolkType.body)
                .foregroundStyle(phrase == nil ? YolkColor.muted : YolkColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3, reservesSpace: true)
                .padding(14)
                .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))

            Button { send() } label: {
                Text(sending ? "sending…" : "send note")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(YolkColor.ink.opacity(canSend ? 1 : 0.3), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSend || sending)

            // Strangers earn nothing, so don't dangle a reward that isn't coming — and
            // don't lead with the payout for friends either. The point is the note.
            Text(subject.isStranger
                 ? "one note per stranger, per day. no reward — that's the point."
                 : "kindness earns a few \(Currency.name), capped so it stays genuine.")
                .font(.caption2).foregroundStyle(YolkColor.muted)
        }
        .padding(YolkSpace.lg)
        .background(YolkColor.shell)
        .yolkDialog($dialog)
    }

    private var canSend: Bool { phrase != nil }

    private func send() {
        guard let phrase else { return }
        sending = true
        Task {
            // By TOKEN. The server validates it against its own table and stores its own
            // copy of the text, so a client can't smuggle arbitrary content through.
            let r = await store.sendPostcardToken(to: subject.userID, token: phrase.id)
            sending = false
            if r.ok {
                Haptics.shared.reward()
                if r.reward > 0 { onReward(r.reward) }
                let m = r.reward > 0
                    ? "your note is on its way. +\(r.reward) \(Currency.name) for the kindness."
                    : "your note is on its way. \(subject.displayName) will love it."
                dialog = YolkDialog(icon: .creature(vibe, .affectionate), title: "sent!", message: m,
                                    primaryTitle: "warm", primaryAction: { dismiss() })
            } else {
                Haptics.shared.warn()
                let msg: String
                switch r.reason {
                case "already_sent":  msg = "you've already left \(subject.displayName) a note today."
                case "not_drifted":   msg = "your yolkling isn't there any more."
                case "blocked":       msg = "you can't reach them."
                case "invalid_token": msg = "that one didn't send. pick another?"
                default:              msg = "couldn't send that just now. try again in a sec."
                }
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                    message: msg, primaryTitle: "okay")
            }
        }
    }
}

/// The received kind notes. Marked read on open.
struct PostcardInbox: View {
    @State var store: SocialStore
    @State private var toast: String?
    @Environment(\.dismiss) private var dismiss
    @State private var dialog: YolkDialog?
    /// Which note's menu is open. Per-row state, because the menu belongs to a card in a
    /// list and a single bool could not say which one.
    @State private var menuFor: Postcard?

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
        .yolkMenu(isPresented: Binding(get: { menuFor != nil },
                                       set: { if !$0 { menuFor = nil } }),
                  alignment: .center) {
            if let card = menuFor { moderationMenu(card) }
        }
        .yolkDialog($dialog)
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.shell)
                    .padding(.horizontal, YolkSpace.md).padding(.vertical, 10)
                    .background(YolkColor.ink, in: Capsule())
                    .padding(.bottom, YolkSpace.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.4))
                        withAnimation { self.toast = nil }
                    }
            }
        }
        .animation(.easeInOut, value: toast)
        .task { await store.markInboxRead() }
    }

    /// Guideline 1.2 requires a way to report content and block the sender. Notes are
    /// composed from a fixed vocabulary so there should be nothing to report, but "should
    /// be" is not a compliance argument, and reports are what prove the vocabulary holds.
    private func moderationMenu(_ card: Postcard) -> some View {
        YolkMenu(width: 250) {
            YolkMenuRow(glyph: .flag, title: "report this note",
                        detail: "we'll look at it", destructive: true) {
                Haptics.shared.warn()
                menuFor = nil
                report(card)
            }
            YolkMenuDivider()
            YolkMenuRow(glyph: nil, title: "block \(card.senderName)",
                        detail: "they can't reach you again", destructive: true) {
                Haptics.shared.warn()
                menuFor = nil
                block(card)
            }
        }
    }

    private func row(_ card: Postcard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.senderName).font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                Spacer()
                if !card.read { Circle().fill(YolkColor.pink).frame(width: 8, height: 8) }
                // Guideline 1.2 requires a way to report objectionable content and block
                // the sender. Notes are composed from a fixed vocabulary so there should
                // be nothing to report — but "should be" isn't a compliance argument, and
                // reports are what prove the vocabulary is holding.
                Button {
                    Haptics.shared.tick()
                    withAnimation(.snappy(duration: 0.22)) { menuFor = card }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(YolkColor.muted)
                        .padding(.leading, 6)
                }
                .buttonStyle(.plain)
            }
            Text(card.message).font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(YolkSpace.md)
        .background(YolkColor.shell2.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
    }

    private func report(_ card: Postcard) {
        Task {
            let ok = await store.report(postcardID: card.id, reason: "objectionable")
            Haptics.shared.select()
            dialog = YolkDialog(
                icon: .creature(.yolk, .curious),
                title: ok ? "thank you" : "hmm",
                message: ok
                    ? "we'll take a look. you can block them too if you'd rather not hear from them."
                    : "couldn't send that just now. try again in a sec.",
                primaryTitle: "okay"
            )
        }
    }

    private func block(_ card: Postcard) {
        Task {
            let ok = await store.block(card.from_id)
            Haptics.shared.warn()
            dialog = YolkDialog(
                icon: .creature(.yolk, .curious),
                title: ok ? "blocked" : "hmm",
                message: ok
                    ? "your yolklings won't cross paths again."
                    : "couldn't do that just now. try again in a sec.",
                primaryTitle: "okay"
            )
        }
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

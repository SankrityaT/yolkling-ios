import SwiftUI

/// Your creature, before and after the swap.
///
/// A trade screen's real question isn't "what are these two objects" — it's *"do I want
/// my yolkling to look like that?"* Two 96pt tiles can't answer it. They show the items
/// in isolation, each modelled on a bare creature, so you have to hold your own outfit in
/// your head and imagine the substitution. That's exactly the work the app should be doing
/// for you.
///
/// So: the left pane is your yolkling as it stands right now, wearing what you're actually
/// wearing. The right pane is the same creature with the trade applied — the item you'd
/// give removed, the item you'd get put on. The comparison is the interface.
///
/// The two panes are deliberately **different sizes**. Equal panes read as a symmetric
/// choice, but this isn't one: "now" is context and "after" is the decision, so "after"
/// gets the larger frame, the rarity aura, and the accent ring.
///
/// Both creatures run live rather than `frozenAt:` — this is the hero of the screen, and a
/// still yolkling next to the breathing one on your home screen reads as broken. It's two
/// clocks on a sheet that has no others.
struct SwapPreview: View {
    let vibe: Vibe
    /// What you're wearing right now — usually `wardrobe.outfit`, carried in via the
    /// published room snapshot.
    let currentOutfit: [Cosmetic]
    /// The item leaving your wardrobe. `nil` until picked.
    let giving: Cosmetic?
    /// The item arriving. `nil` until picked.
    let getting: Cosmetic?

    private var nowSize: CGFloat { 72 }
    private var afterSize: CGFloat { 100 }

    /// The outfit you'd be left with.
    ///
    /// Keyed by slot because the wardrobe is one-item-per-slot (`WardrobeStore.equipped`),
    /// so an incoming hat evicts the hat you're wearing — which is the single most useful
    /// thing this preview can show you and the one thing a tile grid never will. Flattened
    /// back in `CosmeticSlot.allCases` order to match `WardrobeStore.outfit`, since the
    /// renderer stacks in array order.
    private var afterOutfit: [Cosmetic] {
        var bySlot: [CosmeticSlot: Cosmetic] = [:]
        for item in currentOutfit { bySlot[item.slot] = item }
        if let giving, bySlot[giving.slot]?.id == giving.id { bySlot[giving.slot] = nil }
        if let getting { bySlot[getting.slot] = getting }
        return CosmeticSlot.allCases.compactMap { bySlot[$0] }
    }

    /// Both halves picked — only then is "after" a real answer rather than a guess.
    private var ready: Bool { giving != nil && getting != nil }

    /// The item you're wearing that the incoming one would knock off, if any. Worth
    /// calling out by name: losing a hat you didn't offer is a surprise, and a surprise
    /// after the fact is a complaint.
    private var displaced: Cosmetic? {
        guard let getting else { return nil }
        guard let worn = currentOutfit.first(where: { $0.slot == getting.slot }) else { return nil }
        return worn.id == getting.id || worn.id == giving?.id ? nil : worn
    }

    private var accent: Color { Color(hex: 0x5FA86B) }

    var body: some View {
        VStack(spacing: YolkSpace.sm) {
            HStack(alignment: .center, spacing: YolkSpace.xs) {
                nowPane
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ready ? accent : YolkColor.muted)
                    .padding(.horizontal, 2)
                afterPane
            }
            .animation(.snappy(duration: 0.28), value: ready)
            .animation(.snappy(duration: 0.28), value: getting?.id)
            .animation(.snappy(duration: 0.28), value: giving?.id)

            if let displaced {
                Label("your \(displaced.name.lowercased()) comes off", systemImage: "arrow.down")
                    .font(.caption2)
                    .foregroundStyle(YolkColor.muted)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, YolkSpace.md)
        .background(YolkColor.shell2.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: Panes

    private var nowPane: some View {
        pane(label: "now", size: nowSize) {
            YolklingView(vibe: vibe, expression: .content, size: nowSize, outfit: currentOutfit)
                .opacity(0.85)
        }
    }

    private var afterPane: some View {
        // The label stays constant. Swapping the string on `ready` crossfades two
        // different-width texts over each other mid-transition, which reads as a glitch;
        // colour carries the state change on its own.
        pane(label: "after the swap", size: afterSize) {
            ZStack {
                // Only the gained item's rarity glows, and only once the swap is real.
                // A permanent aura would just be decoration on the pane; here it's the
                // payoff landing at the moment the trade becomes possible.
                if let getting, ready {
                    RarityAura(rarity: getting.rarity, size: afterSize * 1.5, intensity: 0.7)
                }
                YolklingView(vibe: vibe, expression: ready ? .happy : .content,
                             size: afterSize, outfit: afterOutfit)
            }
            // Faint enough that the label on top of it stays legible. The ghost is only
            // there to say "your creature goes here" — at 0.3 it competed with the text
            // and neither read.
            .opacity(ready ? 1 : 0.18)
            .overlay {
                if !ready {
                    Text("pick both\nto see it")
                        .font(.caption2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(YolkColor.inkSoft)
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(YolkColor.shell.opacity(0.95),
                                    in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(ready ? accent.opacity(0.55) : YolkColor.line.opacity(0.35),
                              style: StrokeStyle(lineWidth: ready ? 2 : 1.5,
                                                 dash: ready ? [] : [5, 4]))
        }
    }

    private func pane<Content: View>(label: String, size: CGFloat,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) {
            content()
                // Height is pinned to the LARGER creature so the two panes stay on one
                // baseline and neither jumps as outfits change under them. Width stays
                // flexible — a fixed 1.5× box overflows the sheet on a 375pt screen.
                .frame(maxWidth: .infinity)
                .frame(height: afterSize * 1.55)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(label == "now" ? YolkColor.muted : (ready ? accent : YolkColor.muted))
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
}

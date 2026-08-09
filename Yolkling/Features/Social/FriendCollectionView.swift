import SwiftUI

/// What a friend has found, and what you could get from them.
///
/// Trading was legible only to whoever proposed it: you could offer a swap, but you could
/// not browse what someone actually held, so wanting something specific was impossible.
/// This is the other half. You cannot want what you cannot see.
///
/// **Their bond card leads.** It is the one card that is unmistakably theirs, and its finish
/// is earned rather than bought, so it doubles as the honest version of a profile: a
/// beautiful laminate means they have been showing up for themselves. The numbers behind it
/// never cross — see `docs/sql/friend_cards.sql`. Friends get the material, never the
/// figure.
struct FriendCollectionView: View {
    let friend: Friend
    /// What YOU have found, so the grid can say what is new to you. This is the whole
    /// reason to look: a species they have and you do not is a trade worth proposing.
    let mine: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var opened: Species?

    private var theirs: [Species] {
        (friend.found ?? []).compactMap { id in
            SpeciesCatalog.all.first { $0.id == id }
        }
    }

    /// Things they have and you do not. Sorted to the front, because they are the point.
    private var newToMe: [Species] { theirs.filter { !mine.contains($0.id) } }
    private var shared: [Species] { theirs.filter { mine.contains($0.id) } }

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: YolkSpace.lg) {
                    bondCard

                    if friend.found == nil {
                        note("their collection hasn't synced yet. it'll show up next time they open the app.")
                    } else if theirs.isEmpty {
                        note("\(friend.displayName) hasn't found anyone yet.")
                    } else {
                        if !newToMe.isEmpty {
                            section("you haven't found these", newToMe, wanted: true)
                        }
                        if !shared.isEmpty {
                            section("you both have these", shared, wanted: false)
                        }
                    }
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.bottom, YolkSpace.xl)
            }
        }
        .padding(.top, YolkSpace.md)
        .background(YolkColor.shell)
        .fullScreenCover(item: $opened) { sp in
            CardDetailView(face: .species(sp,
                                          number: SpeciesSets.dexNumber(of: sp.id),
                                          outOf: SpeciesSets.dexTotal))
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName).font(YolkType.heading).foregroundStyle(YolkColor.ink)
                Text("\(theirs.count) found").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
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

    /// Their creature, on their earned finish.
    private var bondCard: some View {
        VStack(spacing: YolkSpace.sm) {
            YolkCard(
                face: .bond(name: friend.displayName,
                            vibe: friend.snapshot?.makeVibe(name: friend.displayName) ?? .yolk,
                            outfit: friend.snapshot?.outfit ?? [],
                            // The BAND's midpoint, only to pick a laminate. Never their
                            // real trust value, and never printed.
                            trust: friend.bandTrust,
                            careDays: 0, focusMinutes: 0, speciesFound: theirs.count,
                            createdAt: .now)
                    .withoutPrivateStats(),
                width: 220,
                interactive: true
            )
            Text("tilt it")
                .font(.caption2).foregroundStyle(YolkColor.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, YolkSpace.sm)
    }

    private func section(_ title: String, _ species: [Species], wanted: Bool) -> some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            HStack(spacing: 6) {
                Text(title).font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                if wanted {
                    Text("\(species.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(hex: 0x5FA86B))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(hex: 0x5FA86B).opacity(0.14), in: Capsule())
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 4)], spacing: 6) {
                ForEach(species) { sp in
                    Button {
                        Haptics.shared.select()
                        opened = sp
                    } label: {
                        VStack(spacing: 0) {
                            YolklingView(vibe: sp.vibe, expression: .content, size: 56,
                                         frozenAt: YolklingView.posedT)
                                .frame(height: 82)
                            Text(sp.name).font(.caption2.weight(.medium))
                                .foregroundStyle(YolkColor.ink).lineLimit(1)
                        }
                        // Things you don't have read at full strength; things you both
                        // have step back, so the eye lands on what's worth asking for.
                        .opacity(wanted ? 1 : 0.45)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension YolkCardFace {
    /// Strip the care stats off a card that belongs to someone else.
    ///
    /// `bond(...)` builds the four lifetime figures because that is right for YOUR card.
    /// None of them may cross to a friend: days, focus minutes and trust are a record of how
    /// somebody has been treating themselves, and a card is not a place to publish that.
    /// The finish already says the kind thing.
    func withoutPrivateStats() -> YolkCardFace {
        var f = self
        f.stats = []
        f.flavour = nil
        return f
    }
}

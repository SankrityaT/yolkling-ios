import SwiftUI
import YolklingCore

/// The collection (the Dex): species grouped into small completable sets. Found
/// creatures show in colour; locked ones are cozy mystery eggs (the empty slots
/// are the pull, never a punishment). A seasonal set carries an honest clock. See
/// docs/MONETIZATION.md.
struct CollectionView: View {
    let discovered: Set<String>
    /// nil in previews and screenshot seams; the Dex renders fine without a season.
    var events: EventStore? = nil
    var vibe: Vibe = .yolk
    /// The ids a season just granted, so the player actually receives what they earned.
    ///
    /// `join_event` puts them in the server's `inventory`, but nothing was putting them in
    /// the local `Wallet.owned` — and `Wallet.owns` for a `grantOnly` item is strictly
    /// `owned.contains`, so the seasonal cosmetic stayed locked. A signed-out player never
    /// got it at all. A closure rather than a `Wallet` so the `YOLK_SPECIES` seam, which
    /// has no economy, still constructs.
    var onGranted: ([String]) -> Void = { _ in }
    /// Printed into a shared card image. Empty renders without a code rather than with a
    /// dangling `yolkling.com/add/`.
    var inviteCode: String = ""

    /// The species whose card is open full screen.
    @State private var opened: Species?
    /// Who is currently round at yours, and how to change it. Defaulted so the seams and
    /// a friend's collection (where you have no room to invite anyone into) still build.
    var guestID: String? = nil
    var onSetGuest: ((String?) -> Void)? = nil

    private var allSetIDs: [String] { Array(Set(SpeciesSets.all.flatMap { $0.speciesIDs })) }
    private var totalCount: Int { allSetIDs.count }
    private var discoveredCount: Int { allSetIDs.filter { discovered.contains($0) }.count }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: YolkSpace.lg) {
                header
                if let events, let season = events.featured {
                    SeasonBanner(event: season, vibe: vibe) {
                        // nil = failed (banner resets, retry possible), [] = joined with
                        // nothing granted, ids = joined and granted. These were one [].
                        guard let granted = await events.join(season) else {
                            Haptics.shared.warn()
                            return
                        }
                        if !granted.isEmpty { onGranted(granted) }
                    }
                }
                ForEach(SpeciesSets.all) { setCard($0) }
            }
            .padding(.horizontal, YolkSpace.md)
            .padding(.bottom, 40)
        }
        .background(YolkColor.shell.ignoresSafeArea())
        // Overlaid rather than placed in the header, because that title is centred and a
        // button inside the stack would push it off axis.
        .overlay(alignment: .topLeading) {
            YolkCloseButton { dismiss() }
                .padding(.leading, YolkSpace.md)
                .padding(.top, YolkSpace.sm)
        }
        .task { await events?.refresh() }
        // `fullScreenCover`, matching the pack reveal. A card is the subject, not a detail
        // pane, and a sheet over a grid of cards leaves the grid peeking round it.
        .fullScreenCover(item: $opened) { sp in
            CardDetailView(
                face: .species(sp,
                               number: SpeciesSets.dexNumber(of: sp.id),
                               outOf: SpeciesSets.dexTotal),
                inviteCode: inviteCode,
                species: sp,
                isVisiting: guestID == sp.id,
                // One guest at a time. Asking someone new over sends the last one home,
                // which needs no extra UI and keeps the room from becoming a lineup.
                onToggleVisit: onSetGuest.map { set in
                    { set(guestID == sp.id ? nil : sp.id) }
                }
            )
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("your collection")
                .font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(YolkColor.ink)
            Text("\(discoveredCount) of \(totalCount) discovered")
                .font(YolkType.body).foregroundStyle(YolkColor.muted)
            Text("a few were a week-one gift. the rest are out there to find.")
                .font(.footnote).foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, YolkSpace.md)
    }

    private func setCard(_ set: SpeciesSet) -> some View {
        let found = set.speciesIDs.filter { discovered.contains($0) }.count
        let total = set.speciesIDs.count
        let complete = found == total && total > 0
        return VStack(alignment: .leading, spacing: YolkSpace.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(set.name).font(.system(.headline, design: .rounded)).foregroundStyle(YolkColor.ink)
                        if complete {
                            Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(Color(hex: 0xC9A24B))
                        }
                    }
                    Text(set.blurb).font(.footnote).foregroundStyle(YolkColor.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(found)/\(total)").font(.system(.subheadline, design: .rounded).weight(.bold)).foregroundStyle(YolkColor.inkSoft)
                    if let days = set.seasonDaysLeft(window: SeasonWindows.window(for: set.id)) {
                        Text(days <= 0 ? "ending" : "ends in \(days)d")
                            .font(.caption2.weight(.semibold)).foregroundStyle(Color(hex: 0xE0915E))
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(YolkColor.shell).frame(height: 6)
                    Capsule().fill(complete ? Color(hex: 0xC9A24B) : YolkColor.ink)
                        .frame(width: geo.size.width * CGFloat(found) / CGFloat(max(total, 1)), height: 6)
                }
            }
            .frame(height: 6)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 4)], spacing: 6) {
                ForEach(set.species) { cell($0) }
            }
        }
        .padding(YolkSpace.md)
        .background(set.isSeasonal ? Color(hex: 0xFFF6E0) : YolkColor.shell2, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(set.isSeasonal ? Color(hex: 0xF0D98A) : .clear, lineWidth: 1))
    }

    @ViewBuilder private func cell(_ sp: Species) -> some View {
        if discovered.contains(sp.id) {
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
            }
            .buttonStyle(.plain)
        } else {
            // A card you have not turned over, rather than a padlock.
            //
            // This was a mystery egg, which was already the right instinct (the empty slots
            // are the pull, never a punishment). A face-down card is better on the same axis:
            // an egg says "locked", a face-down card says "not yet flipped", and it is
            // continuous with the scratch reveal that will actually turn it over. `rarity:
            // nil` so the back gives nothing away.
            VStack(spacing: 0) {
                YolkCardBack(rarity: nil, width: 52)
                    .frame(height: 82)
                Text("?").font(.caption2.weight(.bold)).foregroundStyle(YolkColor.muted)
            }
        }
    }
}

/// A cozy "undiscovered" slot: a soft mystery egg, not a sad locked padlock.
private struct MysteryYolk: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.06)).frame(width: size * 0.6, height: size * 0.09).offset(y: size * 0.42).blur(radius: 3)
            Circle().fill(LinearGradient(colors: [Color(hex: 0xEAE0CE), Color(hex: 0xD6C9AF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Text("?").font(.system(size: size * 0.42, weight: .heavy, design: .rounded)).foregroundStyle(.white.opacity(0.75))
        }
    }
}

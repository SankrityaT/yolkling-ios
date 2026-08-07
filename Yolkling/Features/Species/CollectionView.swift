import SwiftUI

/// The collection (the Dex): species grouped into small completable sets. Found
/// creatures show in colour; locked ones are cozy mystery eggs (the empty slots
/// are the pull, never a punishment). A seasonal set carries an honest clock. See
/// docs/MONETIZATION.md.
struct CollectionView: View {
    let discovered: Set<String>
    /// nil in previews and screenshot seams; the Dex renders fine without a season.
    var events: EventStore? = nil
    var vibe: Vibe = .yolk

    private var allSetIDs: [String] { Array(Set(SpeciesSets.all.flatMap { $0.speciesIDs })) }
    private var totalCount: Int { allSetIDs.count }
    private var discoveredCount: Int { allSetIDs.filter { discovered.contains($0) }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: YolkSpace.lg) {
                header
                if let events, let season = events.featured {
                    SeasonBanner(event: season, vibe: vibe) {
                        Task { await events.join(season) }
                    }
                }
                ForEach(SpeciesSets.all) { setCard($0) }
            }
            .padding(.horizontal, YolkSpace.md)
            .padding(.bottom, 40)
        }
        .background(YolkColor.shell.ignoresSafeArea())
        .task { await events?.refresh() }
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

    private func cell(_ sp: Species) -> some View {
        VStack(spacing: 0) {
            if discovered.contains(sp.id) {
                YolklingView(vibe: sp.vibe, expression: .content, size: 56).frame(height: 82)
                Text(sp.name).font(.caption2.weight(.medium)).foregroundStyle(YolkColor.ink).lineLimit(1)
            } else {
                MysteryYolk(size: 56).frame(height: 82)
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

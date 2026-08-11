import SwiftUI
import YolklingCore

/// A browsable gallery of the taxonomy, rendered with the real `YolklingView`
/// (same animation, blink, and breath as the live creature). Reached via the
/// YOLK_SPECIES launch flag for now; it becomes the in-app "species book" later.
/// Founding species are excluded here (grant-only, see docs/species/founding.md).
struct SpeciesGalleryView: View {
    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("the species book")
                        .font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(YolkColor.ink)
                    Text("\(SpeciesCatalog.standard.count) named so far . all code-drawn")
                        .font(.footnote).foregroundStyle(YolkColor.muted)
                }
                .padding(.top, 16)

                section("founding (limited edition)", SpeciesCatalog.founding)
                section("cozy", SpeciesCatalog.cozy)
                section("ocean", SpeciesCatalog.ocean)
                section("garden", SpeciesCatalog.garden)
                section("celestial", SpeciesCatalog.celestial)
            }
            .padding(.bottom, 40)
        }
        .background(YolkColor.shell.ignoresSafeArea())
    }

    private func section(_ title: String, _ list: [Species]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(.headline, design: .rounded)).foregroundStyle(YolkColor.ink)
                .padding(.horizontal, 16)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(list) { s in cell(s) }
            }
            .padding(.horizontal, 8)
        }
    }

    private func cell(_ s: Species) -> some View {
        VStack(spacing: 0) {
            YolklingView(vibe: s.vibe, expression: .content, size: 104).frame(height: 150)
            Text(s.name).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(YolkColor.ink)
            Text(s.rarity.rawValue).font(.system(size: 9, weight: .bold)).tracking(1).textCase(.uppercase)
                .foregroundStyle(rarityColor(s.rarity))
        }
        .padding(.bottom, 8)
    }

    private func rarityColor(_ r: Species.Rarity) -> Color {
        switch r {
        case .founding, .legendary: Color(hex: 0xC9A24B)
        case .epic: Color(hex: 0x9874C9)
        case .rare: Color(hex: 0x5FA9E0)
        case .common: YolkColor.muted
        }
    }
}

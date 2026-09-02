import SwiftUI
import YolklingCore

/// Dev-only: renders each cosmetic in a slot worn on a small creature, so new
/// hand-drawn assets can be eyeballed at a glance. Gated behind YOLK_COSMETICS.
struct CosmeticPreviewGrid: View {
    let items: [Cosmetic]
    var vibe: Vibe = .yolk
    private let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(items) { item in
                    VStack(spacing: 0) {
                        ZStack {
                            RarityAura(rarity: item.rarity, size: 108)
                            YolklingView(vibe: vibe, expression: .happy, size: 74, outfit: [item])
                        }
                        .frame(height: 116)
                        Text(item.name).font(.caption2).foregroundStyle(YolkColor.ink).lineLimit(1)
                    }
                }
            }
            .padding(12)
        }
        .background(YolkColor.shell.ignoresSafeArea())
    }
}

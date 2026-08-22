import SwiftUI

/// One "today, by living" pillar.
///
/// The strip these replace was three flat rectangles containing a number and a word.
/// Correct, and completely inert — the least alive thing on a screen whose entire
/// premise is that something is alive on it. Three things were wrong with it, and each
/// maps to something the genre's best-loved apps do and this did not:
///
/// **It never showed progress, only position.** "0 steps" and "4,210 steps" looked
/// identical in weight. A number cannot say "you are most of the way there"; a vessel
/// filling up can, at a glance, without being read. So the tile fills from the bottom
/// as you approach the goal — skeuomorphic in the Finch sense, where the thing behaves
/// like an object rather than a readout.
///
/// **It opened with zeros.** `0` and `0.0h` first thing in the morning, on an app whose
/// own streak pill deliberately says "day one" rather than "0 days" precisely because
/// starting someone at nil is a scoreboard opening at a deficit. The same rule has to
/// apply here or the principle was decorative. An untouched metric shows a warm word
/// instead of a zero.
///
/// **It did not respond to being touched.** Cuteness is largely physical: rounded,
/// soft, squishy, giving under pressure. A tile that ignores your thumb is furniture.
struct LivingTile: View {
    let glyph: YolkGlyph.Kind
    /// The measured figure, already formatted. nil when there is nothing yet.
    let value: String?
    let label: String
    /// 0...1 toward today's goal. Drives the fill.
    let progress: Double
    /// Today clears the goal.
    let hit: Bool
    /// Shown instead of a zero when nothing has been recorded.
    let emptyWord: String
    var tint: Color = YolkColor.mint
    var onTap: (() -> Void)?

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shown: String { value ?? emptyWord }
    private var isEmpty: Bool { value == nil }

    var body: some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: pressed)
            .onTapGesture {
                guard let onTap else { return }
                Haptics.shared.tick()
                onTap()
            }
            // A press that only registers on a completed tap feels dead under the
            // thumb. This tracks the finger down, which is where the give belongs.
            .onLongPressGesture(minimumDuration: 0, pressing: { down in
                guard onTap != nil, !reduceMotion else { return }
                pressed = down
            }, perform: {})
    }

    private var content: some View {
        HStack(spacing: 8) {
            YolkGlyph(kind: glyph, size: 17, weight: 0.1)
                .foregroundStyle(hit ? tint : YolkColor.muted)
                .frame(width: 17, height: 17)
            VStack(alignment: .leading, spacing: 0) {
                Text(shown)
                    .font(isEmpty ? YolkType.bodySmall.weight(.semibold)
                                  : YolkType.body.weight(.semibold))
                    .foregroundStyle(isEmpty ? YolkColor.muted : YolkColor.ink)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(YolkColor.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) { vessel }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            // Only the finished tile gets an outline. Everything else stays quiet, so
            // "done" is legible across the row without reading a single number.
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(hit ? 0.55 : 0), lineWidth: 1.5)
        }
    }

    /// The fill. Rounded at the top so it reads as a level of something poured in
    /// rather than as a progress bar that happens to be vertical.
    private var vessel: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                YolkColor.shell
                UnevenRoundedRectangle(
                    topLeadingRadius: 10, bottomLeadingRadius: 18,
                    bottomTrailingRadius: 18, topTrailingRadius: 10
                )
                .fill(tint.opacity(hit ? 0.30 : 0.17))
                .frame(height: geo.size.height * min(1, max(0, progress)))
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.85), value: progress)
    }
}

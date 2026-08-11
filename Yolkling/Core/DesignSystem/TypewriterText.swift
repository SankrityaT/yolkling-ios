import SwiftUI
import YolklingCore

/// Reveals text one character at a time with a soft haptic tick as it types.
/// Reserves the full layout up front (a hidden copy) so the container height
/// never jumps while typing. Used for onboarding copy.
struct TypewriterText: View {
    let text: String
    var font: Font = YolkType.body
    var color: Color = YolkColor.ink
    var alignment: TextAlignment = .center
    var charDelay: Double = 0.024
    var startDelay: Double = 0.12

    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            Text(text).opacity(0)                       // reserves the full size
            Text(String(text.prefix(shown)))
        }
        .font(font)
        .foregroundStyle(color)
        .multilineTextAlignment(alignment)
        .frame(maxWidth: .infinity)
        .task(id: text) {
            // Reduce Motion: show the whole line at once. Onboarding copy is information,
            // so it must still arrive — just without the reveal.
            guard !reduceMotion else { shown = text.count; return }
            shown = 0
            try? await Task.sleep(for: .seconds(startDelay))
            for i in 1...max(text.count, 1) {
                shown = i
                if i.isMultiple(of: 3) { Haptics.shared.tick() }   // a soft tick as it types
                try? await Task.sleep(for: .seconds(charDelay))
            }
            shown = text.count
        }
    }
}

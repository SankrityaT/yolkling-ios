import SwiftUI
import YolklingCore

/// The waiting state on the buy button, while StoreKit is doing its thing.
///
/// Replaces a literal "…". An ellipsis is the same three dots a text field shows, a menu
/// shows, and a truncated label shows, so on the one screen where somebody has just
/// committed money it says nothing about whether anything is happening. A payment that
/// looks frozen is how people end up tapping twice.
///
/// Three yolks rising and settling in sequence, because the currency is already the app's
/// unit of "something good is arriving" and a generic spinner would be the one piece of
/// stock UI on an otherwise hand-drawn screen.
///
/// Deterministic in `t` like the rest of the app's motion, so it is reproducible in a
/// screenshot rather than depending on when the view happened to appear.
struct PurchasingIndicator: View {
    var size: CGFloat = 9

    /// One full cycle. Slow enough to read as calm rather than urgent: this is a
    /// reassurance, not a progress bar, and we cannot honestly show progress because
    /// StoreKit does not tell us any.
    private let period: Double = 1.1

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(spacing: size * 0.62) {
                ForEach(0..<3, id: \.self) { i in
                    // A third of a cycle apart, so the three read as one travelling wave
                    // rather than three things blinking.
                    let phase = (t / period + Double(i) * 0.22).truncatingRemainder(dividingBy: 1)
                    // Eased rise and fall. A raw sine spends most of its time mid-travel
                    // and reads as drifting; this sits at rest and then moves.
                    let lift = pow(sin(phase * .pi), 2.2)
                    YolkCoin(size: size, animated: false)
                        .offset(y: -size * 0.55 * lift)
                        .opacity(0.45 + 0.55 * lift)
                        .scaleEffect(0.9 + 0.16 * lift)
                }
            }
            .frame(height: size * 1.9)
        }
        // VoiceOver gets a sentence, not three coins.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("processing your purchase")
    }
}

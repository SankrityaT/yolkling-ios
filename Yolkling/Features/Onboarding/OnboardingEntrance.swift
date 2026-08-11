import SwiftUI

/// Staggered entrances.
///
/// Every onboarding screen used to present its whole layout at once: title, four bullets
/// and a button all arriving on the same frame. That is the difference between copy that
/// was *placed* and copy that was *authored* — the polished flows introduce one element
/// at a time, roughly 50–70ms apart, and the eye follows the order the writer intended
/// instead of picking a starting point at random.
///
/// The interval matters more than the distance. Under about 40ms the rows read as
/// simultaneous and the effect is wasted; over about 90ms the screen feels like it is
/// loading. `step` sits in the middle of that window.
///
/// Motion is small and vertical only — 14pt of rise. A big translation turns a stagger
/// into a slideshow, and anything horizontal fights the reading direction.
struct YolkEntrance: ViewModifier {
    /// Position in the sequence. 0 is first.
    let index: Int
    /// Extra delay before the whole sequence starts, for content that should follow a
    /// hero element rather than race it.
    var after: Double = 0

    /// Gap between consecutive elements.
    private static let step: Double = 0.055
    private static let rise: CGFloat = 14

    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : Self.rise)
            .onAppear {
                guard !reduceMotion else { shown = true; return }
                withAnimation(
                    // A spring rather than an ease, so a row that arrives while the
                    // previous one is still settling inherits its velocity instead of
                    // starting from a dead stop. That overlap is what makes a stagger
                    // feel like one gesture rather than N separate ones.
                    .spring(response: 0.42, dampingFraction: 0.82)
                        .delay(after + Double(index) * Self.step)
                ) { shown = true }
            }
    }
}

extension View {
    /// Bring this in as element `index` of a staggered sequence.
    ///
    /// Indices are per-screen and start at 0. Reduce Motion shows everything immediately
    /// rather than dropping the content, because a stagger is decoration and the copy is
    /// not.
    func yolkEntrance(_ index: Int, after: Double = 0) -> some View {
        modifier(YolkEntrance(index: index, after: after))
    }
}

/// The transition used when one onboarding step replaces another.
///
/// Asymmetric on purpose. The outgoing screen simply fades — it is leaving and should not
/// draw attention on the way out. The incoming screen rises slightly as it fades in, which
/// gives the flow a direction: forward is up. Ten identical crossfades gave the flow no
/// direction at all, so moving between steps felt like being teleported rather than like
/// travelling.
///
/// The hero creature is excluded from this by `matchedGeometryEffect`, which drives its
/// frame directly between the two layouts, so it travels while everything around it
/// changes.
/// The one thing that travels across every onboarding step.
enum OnboardingHero {
    /// Shared `matchedGeometryEffect` id.
    ///
    /// Exactly one view per step may carry this. `StyleButton` renders a small live
    /// creature too, and tagging those would give the group nine sources at once and put
    /// the hero somewhere unpredictable — the previews are content, not the hero.
    static let id = "yolkling.hero"
}

extension Animation {
    /// The pace of the whole flow, in one place.
    ///
    /// Every step used `.easeInOut(duration: 0.4)`, which read as hurried: an ease-in-out
    /// over 0.4s spends so little time in its ramps that it is effectively linear, and
    /// linear motion is most of what "too fast" means even when the duration is fine.
    /// This is longer AND spends more of that length easing, so steps settle instead of
    /// snapping.
    static var onboardingStep: Animation {
        .spring(response: 0.62, dampingFraction: 0.86)
    }
}

extension AnyTransition {
    static var onboardingStep: AnyTransition {
        .asymmetric(
            insertion: .offset(y: 18).combined(with: .opacity),
            removal: .opacity
        )
    }
}

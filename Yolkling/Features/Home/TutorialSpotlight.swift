import SwiftUI

/// Where each tutorial beat points.
enum TutorialTarget: String, CaseIterable {
    case creature, careRow, decorate, living
}

/// Collects the on-screen frame of anything a tutorial beat wants to point at.
///
/// Anchors rather than hardcoded proportions: the old tour positioned its card at 46%
/// or 60% of the screen height and hoped, which meant it had no idea where anything
/// actually was and routinely covered the very control it was describing.
struct TutorialAnchorKey: PreferenceKey {
    static let defaultValue: [TutorialTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TutorialTarget: Anchor<CGRect>],
                       nextValue: () -> [TutorialTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Mark this view as something the first-run tour can point at.
    ///
    /// `transformAnchorPreference`, not `anchorPreference`. The latter SETS the key for
    /// the modified view, which discards whatever its children had already reported — so
    /// tagging the room as `.creature` silently erased the `.decorate` anchor coming from
    /// the button overlaid inside it, and that beat fell back to dimming the whole
    /// screen. Transforming merges into the accumulated value instead, so a target may
    /// contain another target.
    func tutorialTarget(_ target: TutorialTarget) -> some View {
        transformAnchorPreference(key: TutorialAnchorKey.self, value: .bounds) { dict, anchor in
            dict[target] = anchor
        }
    }
}

/// The dim, with a hole cut in it.
///
/// A scrim that covers everything teaches nothing: the player reads a sentence about a
/// button they cannot see, then has to find it afterwards from memory. Cutting the
/// subject out of the dim means the sentence and the thing it describes are on screen
/// together, which is the entire job.
struct SpotlightScrim: View {
    /// Nil dims everything, for beats that are about the screen as a whole.
    let hole: CGRect?
    var cornerRadius: CGFloat = 22

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
            if let hole {
                // `blendMode(.destinationOut)` punches the hole rather than drawing a
                // lighter rectangle over the dim, so what shows through is the real
                // screen at full brightness instead of a washed-out approximation.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .ignoresSafeArea()
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hole)
    }
}

import SwiftUI

/// Swipe down to dismiss, for screens presented with `.fullScreenCover`.
///
/// `.fullScreenCover` has no built-in interactive dismissal, unlike `.sheet` — the only
/// way out is whatever button the screen provides. This restores the gesture people
/// expect from a modal, and gives it the largest target each screen can actually support.
///
/// **Why it is not simply the whole screen everywhere.** A drag recognised over a scroll
/// view and that scroll view's own pan both want the same touch, and SwiftUI resolves it
/// inconsistently: measured on the Shop, scrolled into the hats the drag won and closed
/// the screen mid-browse, while at the top the scroll won and rubber-banded, so the same
/// gesture did two different things depending on where you happened to be. Neither is
/// something to ship.
///
/// So the target is as big as it can be without ever being ambiguous:
///
/// - **Nothing scrolling vertically** (Focus, Decorate — its two scrollers are
///   horizontal): the drag is the whole screen, because nothing can compete for it.
/// - **Vertical scrolling** (Shop, Profile, Friends): the drag must start in the header
///   band above the content, which is the same place a sheet puts its grabber. Scrolling
///   is then never interrupted, and dismissal is always available.
///
/// A screen opts into the second by marking its scroll view with `dismissAwareScroll()`.
/// Nothing else has to change, and a screen that grows a scroll view later gets the
/// correct behaviour by marking it rather than by rediscovering this bug.
private struct HasVerticalScrollKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct SwipeToDismiss: ViewModifier {
    var enabled: Bool
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragHeight: CGFloat = 0

    /// Set once, by a descendant scroll view, before any gesture starts. Deliberately not
    /// derived from live scroll offset: recomputing during a drag re-identifies the
    /// gesture and cancels it mid-swipe.
    @State private var hasVerticalScroll = false

    private let dismissThreshold: CGFloat = 120

    /// The header band, when the screen has content that scrolls under it. Sized to the
    /// title row every one of these screens puts above its content.
    private let grabZone: CGFloat = 100

    private func canBegin(_ value: DragGesture.Value) -> Bool {
        guard enabled else { return false }
        return hasVerticalScroll ? value.startLocation.y <= grabZone : true
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 16)
            .updating($dragHeight) { value, state, _ in
                guard canBegin(value), value.translation.height > 0 else { return }
                state = value.translation.height
            }
            .onEnded { value in
                guard canBegin(value), value.translation.height > dismissThreshold else { return }
                dismiss()
            }
    }

    func body(content: Content) -> some View {
        content
            .offset(y: dragHeight)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.86), value: dragHeight)
            .gesture(drag)
            .onPreferenceChange(HasVerticalScrollKey.self) { hasVerticalScroll = $0 }
    }
}

extension View {
    /// Swipe down to dismiss, for views presented with `.fullScreenCover`.
    ///
    /// Covers the whole screen unless something inside is marked `dismissAwareScroll()`,
    /// in which case the drag starts from the header so it cannot fight scrolling.
    ///
    /// Pass `enabled: false` while the screen is mid-flow and shouldn't be swiped away
    /// (e.g. a running timer), matching whatever condition hides its close button.
    func swipeToDismiss(enabled: Bool = true) -> some View {
        modifier(SwipeToDismiss(enabled: enabled))
    }

    /// Mark a VERTICAL scroll view so the enclosing `swipeToDismiss` keeps out of its way.
    /// Horizontal scrollers do not compete with a downward drag and must not be marked,
    /// or they shrink the dismiss target for no reason.
    func dismissAwareScroll() -> some View {
        preference(key: HasVerticalScrollKey.self, value: true)
    }
}

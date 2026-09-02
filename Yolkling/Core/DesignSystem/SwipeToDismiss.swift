import SwiftUI

/// `.fullScreenCover` has no built-in interactive dismissal, unlike `.sheet` — the only
/// way out is whatever button the screen provides. This restores the swipe-down gesture
/// people expect from any modal.
///
/// **The drag has to START in the header band.** A drag recognised anywhere would fight
/// any scroll view on the screen, and win: in the Shop, scrolled into the hats, swiping
/// down to go back up dismissed the whole screen instead. Same exposure in Profile and
/// Friends. Requiring the gesture to begin above the content is what a sheet's grabber
/// does, and it cannot conflict, because nothing scrolls up there.
///
/// Uniform on every screen rather than only the scrolling ones, so the gesture means the
/// same thing everywhere and adding a scroll view to a screen later cannot quietly
/// reintroduce the bug.
private struct SwipeToDismiss: ViewModifier {
    var enabled: Bool
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragHeight: CGFloat = 0

    private let dismissThreshold: CGFloat = 120

    /// How far down the screen a dismissing drag may begin. Sized to the title band that
    /// every one of these screens puts above its content, and comfortably above where the
    /// Shop's list starts.
    private let grabZone: CGFloat = 100

    private func canBegin(_ value: DragGesture.Value) -> Bool {
        enabled && value.startLocation.y <= grabZone
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
    }
}

extension View {
    /// Swipe down from the top of the screen to dismiss, for views presented with
    /// `.fullScreenCover`. Pass `enabled: false` while the screen is mid-flow and
    /// shouldn't be swiped away (e.g. a running timer), matching whatever condition hides
    /// its close button.
    func swipeToDismiss(enabled: Bool = true) -> some View {
        modifier(SwipeToDismiss(enabled: enabled))
    }
}

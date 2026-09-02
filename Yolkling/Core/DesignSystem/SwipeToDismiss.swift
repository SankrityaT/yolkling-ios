import SwiftUI

/// `.fullScreenCover` has no built-in interactive dismissal, unlike `.sheet` — the only
/// way out is whatever button the screen provides. This restores the swipe-down gesture
/// people expect from any modal, for screens whose root isn't itself a scroll view (where
/// a whole-view drag would fight scrolling).
private struct SwipeToDismiss: ViewModifier {
    var enabled: Bool
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragHeight: CGFloat = 0

    private let dismissThreshold: CGFloat = 120

    private var drag: some Gesture {
        DragGesture(minimumDistance: 16)
            .updating($dragHeight) { value, state, _ in
                guard enabled, value.translation.height > 0 else { return }
                state = value.translation.height
            }
            .onEnded { value in
                guard enabled, value.translation.height > dismissThreshold else { return }
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
    /// Swipe down to dismiss, for views presented with `.fullScreenCover`. Pass
    /// `enabled: false` while the screen is mid-flow and shouldn't be swiped away
    /// (e.g. a running timer), matching whatever condition hides its close button.
    func swipeToDismiss(enabled: Bool = true) -> some View {
        modifier(SwipeToDismiss(enabled: enabled))
    }
}

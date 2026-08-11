import SwiftUI
import YolklingCore

/// Our own menu.
///
/// A native `Menu` cannot be drawn — its rows take `Text` and `Image` only — so custom
/// glyphs are impossible by construction, and it arrives wearing system chrome that belongs
/// to a different app. A sheet is the usual escape hatch and it is too heavy: five options
/// do not deserve a modal, and pushing the room off screen to choose what to do *in the
/// room* is the wrong trade.
///
/// So: a card that grows out of the button that opened it, over a scrim, dismissed by
/// tapping anywhere else. Same interaction as a menu, entirely ours.
///
/// Lives in `Core/DesignSystem` because it is a primitive, and it holds no dependency on
/// anything outside it — which also keeps it safe for the widget compile set.
struct YolkMenu<Content: View>: View {
    var width: CGFloat = 270
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) { content() }
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(YolkColor.shell)
                    // Two shadows rather than one: a tight dark one for the lift off the
                    // page, and a wide soft one for the ambient occlusion. A single shadow
                    // reads as a sticker; two read as a thing above a surface.
                    .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
                    .shadow(color: .black.opacity(0.07), radius: 30, y: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(YolkColor.line, lineWidth: 1)
            )
    }
}

/// One row. A glyph, a title, and an optional line of context underneath.
struct YolkMenuRow: View {
    var glyph: YolkGlyph.Kind?
    let title: String
    var detail: String? = nil
    var destructive: Bool = false
    let action: () -> Void

    /// A muted brick rather than system red. The palette is warm and low-chroma
    /// throughout, and a full-saturation red would be the loudest thing in the app by
    /// some distance — which is not the weight "block someone" should carry.
    private var tint: Color { destructive ? Color(hex: 0xC2543F) : YolkColor.ink }

    var body: some View {
        // No haptic here, deliberately. `Core/DesignSystem` compiles into the widget target
        // and `Core/Haptics` does not, so a design primitive that buzzes would break the
        // widget build. Haptics stay at the call site — the same rule the tokens follow.
        Button(action: action) {
            HStack(spacing: YolkSpace.sm) {
                if let glyph {
                    YolkGlyph(kind: glyph, size: 18)
                        .foregroundStyle(tint)
                        .frame(width: 22)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(YolkType.body.weight(.semibold))
                        .foregroundStyle(tint)
                    if let detail {
                        Text(detail).font(.caption2).foregroundStyle(YolkColor.muted)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, YolkSpace.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A hairline between groups. Inset, so it separates rows rather than cutting the card.
struct YolkMenuDivider: View {
    var body: some View {
        Rectangle().fill(YolkColor.line)
            .frame(height: 1)
            .padding(.horizontal, YolkSpace.md)
    }
}

extension View {
    /// Present a ``YolkMenu`` anchored to this view's corner.
    ///
    /// The scrim is a real full-screen tap target rather than a `.background` gesture,
    /// because a menu you can only dismiss by choosing something is a trap — and on a
    /// screen with other buttons, a stray tap would otherwise fire whatever was underneath.
    ///
    /// It grows from `anchor`, so the card appears to come out of the control you pressed
    /// instead of materialising in the middle of the screen.
    func yolkMenu<C: View>(
        isPresented: Binding<Bool>,
        alignment: Alignment = .bottomTrailing,
        anchor: UnitPoint = .bottomTrailing,
        @ViewBuilder content: @escaping () -> C
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                // Scrim and card in ONE overlay so the scrim sits above the screen's own
                // content and below the menu. In `.background` it would render behind
                // everything and catch no taps at all, which is a dismiss gesture that
                // silently does not exist.
                ZStack(alignment: alignment) {
                    Color.black.opacity(0.06)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.22)) { isPresented.wrappedValue = false }
                        }
                    content()
                        .transition(.scale(scale: 0.88, anchor: anchor).combined(with: .opacity))
                }
            }
        }
    }
}

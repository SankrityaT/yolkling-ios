import SwiftUI

/// The close control every full-screen destination needs.
///
/// A `fullScreenCover` has no swipe-to-dismiss, so a view presented that way without
/// one is a room with no door. Drawn rather than an SF Symbol, like the rest.
struct YolkCloseButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.shared.tick()
            action()
        } label: {
            YolkGlyph(kind: .close, size: 15, weight: 0.12)
                .foregroundStyle(YolkColor.inkSoft)
                .frame(width: 15, height: 15)
                .padding(9)
                .background(YolkColor.shell2, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("close")
    }
}

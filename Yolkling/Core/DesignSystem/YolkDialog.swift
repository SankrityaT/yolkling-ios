import SwiftUI

/// A reusable, cute modal dialog. Present it by setting a `YolkDialog?` state and
/// attaching `.yolkDialog($state)`. Used for over-budget, confirmations, gentle
/// nudges — anywhere we'd otherwise reach for a flat system alert.
struct YolkDialog: Identifiable {
    let id = UUID()
    var icon: Icon = .coins
    var title: String
    var message: String
    var primaryTitle: String = "got it"
    var primaryAction: () -> Void = {}
    var secondaryTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    enum Icon {
        case coins
        case creature(Vibe, Mood)
        case system(String)
    }
}

extension View {
    /// Overlays a cute dialog when `dialog` is non-nil.
    func yolkDialog(_ dialog: Binding<YolkDialog?>) -> some View {
        overlay {
            if let value = dialog.wrappedValue {
                YolkDialogHost(dialog: value) { dialog.wrappedValue = nil }
            }
        }
    }
}

private struct YolkDialogHost: View {
    let dialog: YolkDialog
    var dismiss: () -> Void
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture { close(dialog.secondaryAction) }

            card
                // Reduce Motion: fade in place, no scale travel.
                .scaleEffect(shown || reduceMotion ? 1 : 0.85)
                .opacity(shown ? 1 : 0)
                .padding(YolkSpace.xl)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2)
                                       : .bouncy(duration: 0.45, extraBounce: 0.3)) { shown = true }
        }
    }

    private var card: some View {
        VStack(spacing: YolkSpace.md) {
            icon
                .frame(height: 92)

            Text(dialog.title)
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)
                .multilineTextAlignment(.center)

            Text(dialog.message)
                .font(YolkType.body)
                .foregroundStyle(YolkColor.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: YolkSpace.sm) {
                Button { close(dialog.primaryAction) } label: {
                    Text(dialog.primaryTitle)
                        .font(YolkType.body.weight(.semibold))
                        .foregroundStyle(YolkColor.shell)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)

                if let secondary = dialog.secondaryTitle {
                    Button { close(dialog.secondaryAction) } label: {
                        Text(secondary)
                            .font(YolkType.body)
                            .foregroundStyle(YolkColor.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, YolkSpace.xs)
        }
        .padding(YolkSpace.lg)
        .frame(maxWidth: 320)
        .background(YolkColor.shell, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(YolkColor.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.16), radius: 30, y: 12)
    }

    @ViewBuilder
    private var icon: some View {
        switch dialog.icon {
        case .coins:
            YolkCoin(size: 72)
        case .creature(let vibe, let mood):
            YolklingView(vibe: vibe, expression: mood.expression, size: 92)
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 46))
                .foregroundStyle(YolkColor.yolk)
        }
    }

    private func close(_ action: (() -> Void)?) {
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            action?()
            dismiss()
        }
    }
}

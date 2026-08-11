import SwiftUI
import YolklingCore

/// A short, warm how-to for adding the home screen widget. Shown from the one-time
/// home nudge and from a permanent Profile row.
struct WidgetHowToView: View {
    var onDone: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.lg) {
            Text("put your yolk on your home screen")
                .font(YolkType.title).foregroundStyle(YolkColor.ink)
            step(1, "touch and hold an empty spot on your home screen until the apps jiggle.")
            step(2, "tap the + in the top corner, then search \"yolkling\".")
            step(3, "pick a size and add it. your yolk will be right there, living in its room.")
            Spacer()
            Button { dismiss(); onDone() } label: {
                Text("got it").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(YolkColor.ink, in: Capsule())
            }.buttonStyle(.plain)
        }
        .padding(YolkSpace.lg)
        .background(YolkColor.shell.ignoresSafeArea())
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: YolkSpace.md) {
            Text("\(n)").font(YolkType.body.weight(.bold)).foregroundStyle(YolkColor.shell)
                .frame(width: 28, height: 28).background(YolkColor.ink, in: Circle())
            Text(text).font(YolkType.body).foregroundStyle(YolkColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

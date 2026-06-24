import SwiftUI

/// A quiet, warm reveal when a founding yolkling is granted (a founder code, or a
/// completed referral). No fanfare, just a soft "this is yours", per the grant
/// rules in docs/species/founding.md.
struct FoundingRevealView: View {
    let species: Species
    var onWear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            Spacer()
            Text("a founding yolkling")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .tracking(2).textCase(.uppercase).foregroundStyle(YolkColor.muted)

            YolklingView(vibe: species.vibe, expression: .affectionate, size: 200)
                .frame(height: 250)

            Text(species.name)
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("limited edition. only the early ones carry it.")
                .font(.footnote).foregroundStyle(YolkColor.muted)
            Text(species.personality)
                .font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, YolkSpace.lg).padding(.top, 4)

            Spacer()

            Button {
                Haptics.shared.reward()
                onWear()
                dismiss()
            } label: {
                Text("wear it").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain).padding(.horizontal, YolkSpace.lg)

            Button("keep it for later") { dismiss() }
                .font(.footnote).foregroundStyle(YolkColor.muted)
                .padding(.bottom, YolkSpace.lg)
        }
        .background(YolkColor.shell.ignoresSafeArea())
    }
}

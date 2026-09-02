import SwiftUI
import YolklingCore

/// Shown between signing in and onboarding, while we look for a creature this account
/// already has.
///
/// Without this step the app broke its own promise. The sign-in gate says "signing in
/// keeps a copy safe so they survive a new phone, a reinstall, or a bad day", and then
/// the very next screen made you hatch a brand new creature, because the restore only
/// ran from `HomeView` and `HomeView` only exists once a `Player` is already on the
/// device. Anyone reinstalling was onboarded from scratch with their real creature
/// sitting in the backup untouched.
///
/// Deliberately says "looking" rather than showing a progress bar. It usually takes under
/// a second, and a bar that fills and vanishes is more alarming than a sentence.
struct RestoringView: View {
    @State private var breathe = false

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: .yolk, expression: .curious, size: 150)
                .scaleEffect(breathe ? 1.03 : 0.97)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
            Text("looking for your yolkling")
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("one moment")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, YolkSpace.lg)
        .background(YolkColor.shell)
        .onAppear { breathe = true }
    }
}

import SwiftUI
import YolklingCore

/// The whole watch app, for now: your creature on your wrist. Same renderer as
/// the phone (`YolklingView` from YolklingCore), reconstructed from the snapshot
/// the phone publishes. Tapping pets it — the one interaction that costs nothing
/// and means everything.
struct WatchHomeView: View {
    let sync: WatchSyncModel
    @State private var petToken = 0

    var body: some View {
        ZStack {
            YolkColor.shell.ignoresSafeArea()
            if let snap = sync.snapshot {
                creature(snap)
            } else {
                waitingForPhone
            }
        }
    }

    private func creature(_ snap: WatchCreatureSnapshot) -> some View {
        VStack(spacing: 2) {
            YolklingView(
                vibe: snap.vibe,
                expression: snap.expression,
                size: 88,
                outfit: snap.outfit,
                petToken: petToken
            )
            .onTapGesture { petToken += 1 }

            Text(snap.name)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(YolkColor.ink)
            Text(snap.trustStage.label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(YolkColor.inkSoft)
        }
    }

    /// First launch before any sync: a resting default yolk, and the one thing
    /// the user needs to know.
    private var waitingForPhone: some View {
        VStack(spacing: 4) {
            YolklingView(vibe: .yolk, expression: .waiting, size: 72)
            Text("open Yolkling on your iPhone to meet your yolk here")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(YolkColor.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

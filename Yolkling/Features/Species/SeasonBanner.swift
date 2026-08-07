import SwiftUI

/// The running season, surfaced where species live.
///
/// Deliberately states what it IS and when it ends, and nothing else — no countdown
/// timer ticking down, no "hurry", no red. `MONETIZATION.md` allows honest scarcity
/// ("limited = real, time-bound, clearly explained") and forbids manufactured loss. The
/// difference is entirely in the framing: "the garden ones are out, briefly" invites,
/// "2 DAYS LEFT!!" pressures.
struct SeasonBanner: View {
    let event: SeasonalEvent
    let vibe: Vibe
    var onJoin: () -> Void

    @State private var joining = false

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            HStack(spacing: YolkSpace.sm) {
                YolklingView(vibe: vibe, expression: .excited, size: 54,
                             frozenAt: YolklingView.posedT)
                    .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    if let days = event.daysLeft {
                        // Plain and calm. "here for N more days", not a countdown.
                        Text(days <= 0 ? "last day" : "here for \(days) more days")
                            .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                    }
                }
                Spacer(minLength: 0)
            }

            if !event.blurb.isEmpty {
                Text(event.blurb)
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if event.joined {
                Label("you're in", systemImage: "checkmark.circle.fill")
                    .font(YolkType.bodySmall.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x73C57A))
            } else {
                Button {
                    joining = true
                    onJoin()
                } label: {
                    Text(joining ? "joining…" : "join the season")
                        .font(YolkType.bodySmall.weight(.semibold))
                        .foregroundStyle(YolkColor.shell)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(joining)
            }
        }
        .padding(YolkSpace.md)
        .background(Color(hex: 0xFFF6E0), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22)
            .strokeBorder(Color(hex: 0xF0D98A), lineWidth: 1))
    }
}

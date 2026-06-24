import SwiftUI

/// A gentle daily mood check-in: pick how you feel, your yolkling feels it too,
/// and you earn Yolks (once a day). The first real wellbeing primitive, and the
/// thing that turns the TODAY "check in" card into the actual loop.
struct MoodCheckInView: View {
    let vibe: Vibe
    let alreadyToday: Bool
    var onPick: (Mood) -> Void

    private let feelings: [(label: String, mood: Mood)] = [
        ("amazing", .excited),
        ("good", .happy),
        ("okay", .content),
        ("low", .low),
        ("tired", .tired),
        ("rough", .unwell),
    ]

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Capsule().fill(YolkColor.line).frame(width: 40, height: 5).padding(.top, YolkSpace.sm)

            Text("how are you feeling?")
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)
            Text(alreadyToday ? "you checked in today. update it anytime." : "your yolkling feels it too. (+10 Yolks)")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: YolkSpace.md), count: 3), spacing: YolkSpace.lg) {
                ForEach(feelings, id: \.label) { feeling in
                    Button { onPick(feeling.mood) } label: {
                        VStack(spacing: 4) {
                            YolklingView(vibe: vibe, expression: feeling.mood.expression, size: 50)
                                .frame(width: 84, height: 90)
                            Text(feeling.label)
                                .font(YolkType.bodySmall)
                                .foregroundStyle(YolkColor.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, YolkSpace.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell)
    }
}

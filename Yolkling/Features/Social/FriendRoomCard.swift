import SwiftUI
import YolklingCore

/// A live mini-room card showing a friend's yolk in their decorated room,
/// plus ambient status (new activity, mood, asleep, streak) and a wave button.
/// Tapping the card body opens VisitView via the onOpen closure.
///
/// Used by the friends grid in FriendsView (assembled in Task 8).
struct FriendRoomCard: View {
    let friend: Friend
    let store: SocialStore
    var onOpen: (Friend) -> Void

    @State private var waved = false
    @State private var friendWaveToken = 0   // bump to make the friend's yolk wave back

    private var snapshot: RoomSnapshot? { friend.snapshot }

    // MARK: Status chips

    /// True if the friend updated their room since we last visited them.
    private var isNew: Bool {
        guard let updated = friend.updatedDate else { return false }
        let last = store.lastVisited(friend.user_id)
        return last == nil || updated > last!
    }

    private var moodLabel: String? {
        guard let snap = snapshot else { return nil }
        return Mood(rawValue: snap.moodRaw)?.label.lowercased()
    }

    private var isAsleep: Bool {
        guard let snap = snapshot, let h = snap.hour else { return false }
        return YolkExpression.phase(forHour: h) == .night
    }

    private var streak: Int {
        snapshot?.streak ?? 0
    }

    // MARK: Room components

    private var vibe: Vibe {
        snapshot?.makeVibe(name: friend.displayName) ?? .yolk
    }

    private var expression: YolkExpression {
        snapshot?.expression ?? .happy
    }

    private var theme: RoomTheme {
        snapshot?.theme ?? RoomThemes.cozy
    }

    private var outfit: [Cosmetic] {
        snapshot?.outfit ?? []
    }

    private var decor: [RoomDecor] {
        snapshot?.decor ?? []
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Live mini-room
            Button { onOpen(friend) } label: {
                RoomView(
                    vibe: vibe,
                    expression: expression,
                    theme: theme,
                    outfit: outfit,
                    decor: decor,
                    waveToken: friendWaveToken
                )
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.black.opacity(0.07), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Name + status row
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(YolkType.body.weight(.semibold))
                    .foregroundStyle(YolkColor.ink)
                    .lineLimit(1)

                statusRow
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 2)

            // Wave button
            waveButton
                .padding(.top, 6)
        }
        .padding(10)
        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Status row

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 6) {
            if isNew {
                Text("✨ new")
                    .font(YolkType.bodySmall.weight(.medium))
                    .foregroundStyle(YolkColor.yolk)
            }
            if let label = moodLabel, !label.isEmpty {
                Text(label)
                    .font(YolkType.bodySmall)
                    .foregroundStyle(YolkColor.muted)
            }
            if isAsleep {
                Text("😴")
                    .font(YolkType.bodySmall)
            }
            if streak > 0 {
                Text("🔥 \(streak)")
                    .font(YolkType.bodySmall.weight(.medium))
                    .foregroundStyle(YolkColor.inkSoft)
            }
        }
        // hide the row entirely when nothing to show
        .opacity((isNew || moodLabel != nil || isAsleep || streak > 0) ? 1 : 0)
    }

    // MARK: Wave button

    private var waveButton: some View {
        Button {
            guard !waved else { return }
            Haptics.shared.select()
            // Optimistic with a rollback; see VisitView.waveButton for the reasoning.
            waved = true
            friendWaveToken += 1   // their yolk waves back
            Task {
                if await !store.sendWave(to: friend.user_id) {
                    Haptics.shared.warn()
                    withAnimation(.easeInOut(duration: 0.2)) { waved = false }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(waved ? "waved!" : "👋 wave")
                    .font(YolkType.bodySmall.weight(.medium))
                    .foregroundStyle(waved ? YolkColor.muted : YolkColor.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(waved ? YolkColor.shell2 : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(YolkColor.muted.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(waved)
    }
}

import SwiftUI

/// A count-free "while you were away" reciprocity strip.
/// Shows warm lines for waves, room visits, and redecorations since the user was last active.
/// Returns EmptyView when all three input arrays are empty.
struct WhileYouWereAwayStrip: View {

    let waves: [Wave]
    let visits: [Visit]
    let redecorated: [Friend]
    var onTap: (String) -> Void

    // MARK: - Assembled rows

    private struct Row: Identifiable {
        let id: String
        let icon: String
        let text: String
        let friendID: String
    }

    private var rows: [Row] {
        var result: [Row] = []

        // Waves first (newest-ish already from the server)
        for wave in waves {
            result.append(Row(
                id: "wave-\(wave.from_id)",
                icon: "👋",
                text: "\(wave.senderName) waved",
                friendID: wave.from_id
            ))
        }

        // Visits
        for visit in visits {
            result.append(Row(
                id: "visit-\(visit.visitor_id)",
                icon: "🏠",
                text: "\(visit.visitorName) visited your room",
                friendID: visit.visitor_id
            ))
        }

        // Redecorations
        for friend in redecorated {
            result.append(Row(
                id: "redecor-\(friend.user_id)",
                icon: "✨",
                text: "\(friend.displayName) redecorated",
                friendID: friend.user_id
            ))
        }

        return Array(result.prefix(6))
    }

    // MARK: - Body

    var body: some View {
        if rows.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: YolkSpace.sm) {
                Text("while you were away")
                    .font(YolkType.label)
                    .tracking(1.5)
                    .textCase(.lowercase)
                    .foregroundStyle(YolkColor.muted)

                VStack(alignment: .leading, spacing: YolkSpace.sm) {
                    ForEach(rows) { row in
                        Button {
                            onTap(row.friendID)
                        } label: {
                            HStack(spacing: YolkSpace.sm) {
                                Text(row.icon)
                                    .font(.system(size: 15))
                                Text(row.text)
                                    .font(YolkType.bodySmall)
                                    .foregroundStyle(YolkColor.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, YolkSpace.md)
            .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, YolkSpace.lg)
        }
    }
}

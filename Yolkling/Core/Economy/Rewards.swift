import Foundation

/// Earning rules: streak milestone bonuses + the weekly challenge. Earning speeds
/// up by DOING MORE self-care (and inviting friends), never by paying. The hard
/// line: you never buy Yolks. See docs/REWARDS.md.
enum Rewards {
    /// A one-time bonus when the kind care streak first reaches a milestone day.
    static func streakBonus(for streak: Int) -> Int? {
        switch streak {
        case 3:   20
        case 7:   50
        case 14:  100
        case 30:  250
        case 60:  400
        case 100: 750
        default:  nil
        }
    }

    /// Weekly challenge: care for your yolk on this many days in a calendar week.
    static let weeklyTarget = 5
    static let weeklyReward = 100
}

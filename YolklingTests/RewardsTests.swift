import Testing
@testable import Yolkling

/// Exercises `Rewards`: the streak-milestone bonus table and the weekly-challenge
/// constants. Source of truth: `Yolkling/Core/Economy/Rewards.swift`.
@Suite("Rewards")
struct RewardsTests {

    // MARK: streakBonus milestones

    @Test("Each documented milestone returns its exact bonus")
    func milestonesReturnExactBonuses() {
        #expect(Rewards.streakBonus(for: 3)   == 20)
        #expect(Rewards.streakBonus(for: 7)   == 50)
        #expect(Rewards.streakBonus(for: 14)  == 100)
        #expect(Rewards.streakBonus(for: 30)  == 250)
        #expect(Rewards.streakBonus(for: 60)  == 400)
        #expect(Rewards.streakBonus(for: 100) == 750)
    }

    @Test("Non-milestone streaks return nil (never zero)",
          arguments: [0, 1, 2, 4, 5, 6, 8, 13, 15, 29, 31, 59, 61, 99, 101, 200])
    func nonMilestonesReturnNil(_ streak: Int) {
        #expect(Rewards.streakBonus(for: streak) == nil)
    }

    @Test("Negative streaks return nil")
    func negativeStreaksReturnNil() {
        #expect(Rewards.streakBonus(for: -1) == nil)
        #expect(Rewards.streakBonus(for: -100) == nil)
    }

    // MARK: weekly challenge constants

    @Test("Weekly target and reward constants")
    func weeklyConstants() {
        #expect(Rewards.weeklyTarget == 5)
        #expect(Rewards.weeklyReward == 100)
    }
}

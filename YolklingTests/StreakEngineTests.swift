import Testing
import Foundation
import YolklingCore
@testable import Yolkling

/// Exercises `StreakEngine.recordCare`. Source of truth:
/// `Yolkling/Core/Creature/CareEngines.swift`.
///
/// NOTE on date injection: `recordCare` takes an injected `today` and uses it for
/// the day-gap arithmetic, BUT the "same day, no-op" branch uses
/// `Calendar.current.isDateInToday(last)`, which compares against the *real*
/// system day — not the injected `today`. So the same-day test anchors `today`
/// and `last` to the real `.now`; every other case derives `last` from `today`
/// via whole-day offsets, which is deterministic because the engine reduces both
/// endpoints to `startOfDay`.
@Suite("StreakEngine")
struct StreakEngineTests {

    private let cal = Calendar.current

    /// `today` at a fixed instant, and `last` offset by whole days from it.
    private func day(_ offset: Int, from base: Date) -> Date {
        cal.date(byAdding: .day, value: offset, to: base)!
    }

    @Test("First care (no prior care) starts the streak at >= 1")
    func firstCareStartsStreak() {
        let r = StreakEngine.recordCare(streak: 0, lastCare: nil, restTokens: 0, today: .now)
        #expect(r.streak >= 1)
        #expect(r.streak == 1)
        #expect(r.restUsed == false)
    }

    @Test("First care never lowers an existing streak below 1")
    func firstCareKeepsExistingStreak() {
        let r = StreakEngine.recordCare(streak: 4, lastCare: nil, restTokens: 1, today: .now)
        #expect(r.streak == 4) // max(streak, 1)
    }

    @Test("Same-day repeat is a no-op")
    func sameDayIsNoOp() {
        // `isDateInToday` checks the real system day, so anchor to real now.
        let today = Date.now
        let earlierToday = cal.startOfDay(for: today)
        let r = StreakEngine.recordCare(streak: 5, lastCare: earlierToday, restTokens: 2, today: today)
        #expect(r.streak == 5)
        #expect(r.restTokens == 2)
        #expect(r.restUsed == false)
    }

    @Test("Consecutive day increments the streak by one")
    func consecutiveDayIncrements() {
        let today = Date.now
        let yesterday = day(-1, from: today)
        let r = StreakEngine.recordCare(streak: 3, lastCare: yesterday, restTokens: 0, today: today)
        #expect(r.streak == 4)
        #expect(r.restUsed == false)
    }

    @Test("A rest token is granted on every 7th consecutive day")
    func restTokenGrantedEverySeventhDay() {
        let today = Date.now
        let yesterday = day(-1, from: today)
        // streak 6 -> 7 completes a full week -> +1 token
        let r = StreakEngine.recordCare(streak: 6, lastCare: yesterday, restTokens: 0, today: today)
        #expect(r.streak == 7)
        #expect(r.restTokens == 1)
    }

    @Test("Rest-token grant is capped at 3")
    func restTokensCappedAtThree() {
        let today = Date.now
        let yesterday = day(-1, from: today)
        // streak 6 -> 7 would grant, but already at cap
        let r = StreakEngine.recordCare(streak: 6, lastCare: yesterday, restTokens: 3, today: today)
        #expect(r.streak == 7)
        #expect(r.restTokens == 3) // min(3 + 1, 3)
    }

    @Test("Non-week-boundary consecutive day grants no token")
    func nonBoundaryGrantsNoToken() {
        let today = Date.now
        let yesterday = day(-1, from: today)
        let r = StreakEngine.recordCare(streak: 2, lastCare: yesterday, restTokens: 1, today: today)
        #expect(r.streak == 3)
        #expect(r.restTokens == 1)
    }

    @Test("A one-day gap WITH a token spends it, advances streak, marks rest used")
    func oneDayGapWithTokenIsAbsorbed() {
        // A single missed day => the gap between last and today is 2 calendar days.
        let today = Date.now
        let twoDaysAgo = day(-2, from: today)
        let r = StreakEngine.recordCare(streak: 5, lastCare: twoDaysAgo, restTokens: 2, today: today)
        #expect(r.restUsed == true)
        #expect(r.restTokens == 1)      // one token consumed
        #expect(r.streak == 6)          // real API advances streak + 1 (the missed day is paused, not lost)
    }

    @Test("A one-day gap with 0 tokens resets gently to 1")
    func oneDayGapWithoutTokenResets() {
        let today = Date.now
        let twoDaysAgo = day(-2, from: today)
        let r = StreakEngine.recordCare(streak: 9, lastCare: twoDaysAgo, restTokens: 0, today: today)
        #expect(r.streak == 1)
        #expect(r.restUsed == false)
        #expect(r.restTokens == 0)      // nothing taken away
    }

    @Test("A multi-day gap resets to 1 (even with tokens available)")
    func multiDayGapResets() {
        let today = Date.now
        let fiveDaysAgo = day(-5, from: today)
        let r = StreakEngine.recordCare(streak: 12, lastCare: fiveDaysAgo, restTokens: 3, today: today)
        #expect(r.streak == 1)
        #expect(r.restUsed == false)
        #expect(r.restTokens == 3)      // tokens are preserved on a gentle reset
    }

    @Test("a future lastCare (clock moved back) does not bank a streak day")
    func futureLastCareIsNotConsecutive() {
        let cal = Calendar.current
        let today = Date()
        // lastCare a day AHEAD of today: the shape produced by winding the clock forward,
        // caring, then winding it back.
        let future = cal.date(byAdding: .day, value: 1, to: today)!
        let r = StreakEngine.recordCare(streak: 5, lastCare: future, restTokens: 2, today: today)
        #expect(r.streak == 1, "a negative day-delta was treated as consecutive")
        #expect(r.restUsed == false)
    }

    @Test("an ordinary consecutive day still advances")
    func consecutiveStillWorks() {
        let cal = Calendar.current
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let r = StreakEngine.recordCare(streak: 5, lastCare: yesterday, restTokens: 2, today: today)
        #expect(r.streak == 6)
    }

}

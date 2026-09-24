import Foundation
import Testing
@testable import Yolkling

/// The Screen Time callbacks are not a tidy stream: they arrive late, batched, out of
/// order, sometimes twice, sometimes after midnight carrying no date, and on iOS 26
/// sometimes on an idle phone that was only plugged in. Every rule below exists because
/// one of those produced a visibly wrong number in somebody's app.
struct ScreenTimeLadderTests {

    private func clean() -> UserDefaults {
        let d = ScreenTimeShare.defaults!
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("usage.") { d.removeObject(forKey: k) }
        return d
    }

    // MARK: The ladder

    @Test func eventNamesCarryTheirMinutes() {
        let name = ScreenTimeLadder.eventName(minutes: 45)
        #expect(ScreenTimeLadder.minutes(fromEventName: name) == 45)
    }

    @Test func foreignEventNamesAreIgnored() {
        // Another app's event, or one of Apple's, must never be counted as usage.
        #expect(ScreenTimeLadder.minutes(fromEventName: "someone.elses.event") == nil)
    }

    @Test func theLadderCoversTheDayInEvenSteps() {
        let steps = ScreenTimeLadder.steps
        #expect(steps.first == 15)
        #expect(steps.last == 12 * 60)
        #expect(steps.count == 48)              // comfortably inside any practical limit
        #expect(Set(steps).count == steps.count)
    }

    // MARK: Recording

    @Test func theHighestThresholdWins() {
        _ = clean()
        let now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        ScreenTimeShare.record(minutes: 30, now: now)
        ScreenTimeShare.record(minutes: 60, now: now)
        // Out of order: an older event flushed late must not lower the figure.
        ScreenTimeShare.record(minutes: 45, now: now)
        #expect(ScreenTimeShare.usedMinutesToday(now) == 60)
    }

    @Test func aRepeatedEventDoesNotDoubleCount() {
        _ = clean()
        let now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        ScreenTimeShare.record(minutes: 30, now: now)
        ScreenTimeShare.record(minutes: 30, now: now)   // the documented once-per-interval callback fires twice in the wild
        #expect(ScreenTimeShare.usedMinutesToday(now) == 30)
    }

    @Test func nothingReportedYetIsNilNotZero() {
        _ = clean()
        // nil means "no news", which the tile shows as "counting". Zero would be a claim
        // that the phone has not been touched, and would feed the creature a perfect day.
        #expect(ScreenTimeShare.usedMinutesToday(.now) == nil)
    }

    @Test func aClaimBiggerThanTheDayIsRefused() {
        _ = clean()
        let at9am = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now)!
        // iOS 26 fires thresholds on an idle device; a replayed event from yesterday looks
        // identical. 12 hours of usage by 9am is impossible, so it is not believed.
        ScreenTimeShare.record(minutes: 12 * 60, now: at9am)
        #expect(ScreenTimeShare.usedMinutesToday(at9am) == nil)
    }

    @Test func readingIsAlsoCappedByTheClock() {
        _ = clean()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        ScreenTimeShare.record(minutes: 600, now: noon)          // 10h by noon: allowed, 720 elapsed
        let at1am = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: .now)!
        // Read back early in the day (clock changed, timezone moved): never more than elapsed.
        #expect((ScreenTimeShare.usedMinutesToday(at1am) ?? 0) <= ScreenTimeShare.minutesElapsedToday(at1am))
    }

    @Test func eachDayHasItsOwnBucket() {
        _ = clean()
        let today = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        let yesterday = today.addingTimeInterval(-86_400)
        ScreenTimeShare.record(minutes: 120, now: yesterday)
        // An event the system held overnight lands in yesterday, not on top of today.
        #expect(ScreenTimeShare.usedMinutesToday(today) == nil)
        #expect(ScreenTimeShare.usedMinutesToday(yesterday) == 120)
    }
}

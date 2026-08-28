import Testing
import Foundation
@testable import Yolkling

/// Exercises `AppReview`'s policy. Source of truth:
/// `Yolkling/Core/Growth/AppReview.swift`.
@Suite("AppReview")
@MainActor
struct AppReviewTests {

    /// A defaults database of its own per test, so nothing leaks between them or into
    /// the real one.
    private func freshStore(_ name: String) -> ReviewFlagStore {
        let d = UserDefaults(suiteName: "test.\(name).\(UUID().uuidString)")!
        return ReviewFlagStore(defaults: d)
    }

    @Test("Does not ask before the 7-day milestone")
    func silentEarly() {
        let store = freshStore("early")
        for streak in [0, 1, 2, 3, 6] {
            #expect(AppReview.shouldAsk(atStreak: streak, store: store) == false,
                    "asked at \(streak)")
        }
    }

    @Test("Asks at exactly 7 days")
    func asksAtBoundary() {
        #expect(AppReview.shouldAsk(atStreak: 7, store: freshStore("seven")) == true)
    }

    @Test("Asks at later milestones too, if it never asked before")
    func asksLater() {
        #expect(AppReview.shouldAsk(atStreak: 30, store: freshStore("thirty")) == true)
    }

    @Test("Asks once per install and never again")
    func asksOnlyOnce() {
        let store = freshStore("once")
        #expect(AppReview.shouldAsk(atStreak: 7, store: store) == true)
        // Every later milestone must stay silent, or a long-running player gets
        // prompted six times over a hundred days.
        for streak in [14, 30, 60, 100] {
            #expect(AppReview.shouldAsk(atStreak: streak, store: store) == false,
                    "asked again at \(streak)")
        }
    }

    @Test("A refused early milestone does not burn the one ask")
    func earlyDoesNotConsume() {
        let store = freshStore("noburn")
        #expect(AppReview.shouldAsk(atStreak: 3, store: store) == false)
        // If the 3-day check had recorded the ask, this would be false and the app
        // would never prompt anyone.
        #expect(AppReview.shouldAsk(atStreak: 7, store: store) == true)
    }
}

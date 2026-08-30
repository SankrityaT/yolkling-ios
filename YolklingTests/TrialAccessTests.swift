import Testing
import Foundation
@testable import Yolkling

/// Exercises `TrialAccess`, the one day look around that lets somebody (and Apple's
/// reviewer) into the app before signing in. Source of truth:
/// `Yolkling/Core/Auth/TrialAccess.swift`.
@Suite("TrialAccess")
@MainActor
struct TrialAccessTests {

    /// Fresh defaults per test, so a started trial never leaks between them or into the
    /// real database.
    private func fresh(_ name: String) {
        TrialAccess.defaults = UserDefaults(suiteName: "test.trial.\(name).\(UUID().uuidString)")!
    }

    @Test("Before it starts, there is no access and no expiry")
    func notStarted() {
        fresh("none")
        #expect(TrialAccess.hasStarted == false)
        #expect(TrialAccess.isActive == false)
        #expect(TrialAccess.hasExpired == false)   // never taken is NOT expired
    }

    @Test("Starting it grants access")
    func startGrants() {
        fresh("start")
        TrialAccess.begin()
        #expect(TrialAccess.hasStarted)
        #expect(TrialAccess.isActive)
        #expect(TrialAccess.hasExpired == false)
    }

    @Test("A second begin does not extend the window")
    func beginIsIdempotent() {
        fresh("idem")
        TrialAccess.begin()
        let first = TrialAccess.startedAt
        TrialAccess.begin()
        #expect(TrialAccess.startedAt == first)
    }

    @Test("Past the window it expires, and hasStarted stays true")
    func expires() {
        fresh("expire")
        TrialAccess.begin()
        TrialAccess.expireNow()
        #expect(TrialAccess.isActive == false)
        #expect(TrialAccess.hasExpired)
        // Must stay true, or the gate would offer another day and the trial would be
        // renewable forever by anyone who waited.
        #expect(TrialAccess.hasStarted)
    }

    @Test("An expired trial cannot be restarted by calling begin again")
    func cannotRenew() {
        fresh("renew")
        TrialAccess.begin()
        TrialAccess.expireNow()
        TrialAccess.begin()
        #expect(TrialAccess.isActive == false, "the look around was renewed")
    }

    @Test("hoursLeft never reads zero while access still works")
    func hoursNeverZeroWhileActive() {
        fresh("hours")
        TrialAccess.begin()
        // Wind to the last minutes of the window.
        TrialAccess.defaults.set(Date().addingTimeInterval(-TrialAccess.window + 120),
                                 forKey: "yolk.trialStartedAt")
        #expect(TrialAccess.isActive)
        // "0 hours left" on a screen that still works reads as a bug.
        #expect(TrialAccess.hoursLeft >= 1)
    }

    @Test("hoursLeft is zero once expired")
    func hoursZeroWhenExpired() {
        fresh("hours0")
        TrialAccess.begin()
        TrialAccess.expireNow()
        #expect(TrialAccess.hoursLeft == 0)
    }
}

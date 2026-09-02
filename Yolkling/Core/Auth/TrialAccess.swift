import Foundation

/// A one day look around before signing in is required.
///
/// **Why it exists.** The sign-in gate had no way past it. Apple's beta review could not
/// get into the app at all (Guideline 2.1(a)) because Sign in with Apple is the only
/// method and there are no credentials to hand over. More importantly, anyone whose Sign
/// in with Apple fails, on a device with no Apple Account signed in, was permanently
/// locked out of an app whose whole promise is a creature that cannot truly die.
///
/// **Why a day rather than forever.** The account is not decoration: the creature is
/// backed up to it and the friend graph is keyed on it. A permanent bypass would quietly
/// create people whose creature dies with the app, which is the exact failure this app
/// says it prevents. A day is long enough to decide you care and short enough that
/// nobody builds a real attachment to something unbacked.
///
/// **The creature is never destroyed at expiry.** The trial ending puts the sign-in
/// screen back in front of a creature that still exists on the device; signing in adopts
/// that same creature rather than starting a new one. `RootView` enforces that.
/// Destroying someone's yolk to enforce a deadline would be indefensible.
///
/// Deliberately NOT defended against clock tampering. Moving the device clock back to
/// extend the trial is possible, it is also possible to just sign in, and treating
/// customers as adversaries over a free look around would cost more than it saves.
@MainActor
enum TrialAccess {

    /// How long the look around lasts.
    static let window: TimeInterval = 24 * 60 * 60

    private static let key = "yolk.trialStartedAt"

    /// Swappable so tests get their own database instead of writing into the real one
    /// and leaking a started trial between runs.
    static var defaults: UserDefaults = .standard

    /// When the trial began, or nil if it never has.
    static var startedAt: Date? {
        defaults.object(forKey: key) as? Date
    }

    /// Whether the trial has ever been taken. Once true it stays true, so the skip is
    /// offered once and not renewed by deleting the creature.
    static var hasStarted: Bool { startedAt != nil }

    /// Start the clock. Idempotent: a second call does not extend anything.
    static func begin() {
        guard startedAt == nil else { return }
        defaults.set(Date(), forKey: key)
    }

    /// Whether the app is currently usable without an account.
    static var isActive: Bool {
        guard let startedAt else { return false }
        return Date().timeIntervalSince(startedAt) < window
    }

    /// Whole hours left, floored, minimum 1 while still active. Used for the reminder on
    /// Home; "0 hours left" while the app still works would read as a bug.
    static var hoursLeft: Int {
        guard let startedAt, isActive else { return 0 }
        let remaining = window - Date().timeIntervalSince(startedAt)
        return max(1, Int(remaining / 3600))
    }

    /// The trial was taken and has run out.
    static var hasExpired: Bool { hasStarted && !isActive }

    #if DEBUG
    /// Dev only: wind the clock so the expiry screen can be seen without waiting a day.
    static func expireNow() {
        defaults.set(Date().addingTimeInterval(-window - 60), forKey: key)
    }
    static func reset() { defaults.removeObject(forKey: key) }
    #endif
}

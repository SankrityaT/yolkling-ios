import Foundation
import FamilyControls
import DeviceActivity

/// The "time off your phone" half of grow-by-living.
///
/// **How it gets a number at all.** Apple never hands an app a usage figure. The only
/// channel out of the Screen Time sandbox is a `DeviceActivityMonitor` extension being told
/// "usage passed a threshold you registered", so this registers a ladder of thresholds
/// (15, 30, 45 … minutes) for a repeating daily interval, and the extension records the
/// highest one that fires. See `ScreenTimeShare` for the storage rules, which exist because
/// those callbacks arrive late, batched, out of order and occasionally impossible.
///
/// **What counts.** The events carry no app selection, which Apple defines as "all
/// applications, categories and web domains", so this measures total device screen time
/// without asking anyone to pick apps. Thresholds accrue only while an app or site is
/// *frontmost*, so background audio, background refresh and notifications do not inflate it
/// — unlike `DeviceActivityReport.totalActivityDuration`, which also counts the Home Screen
/// and idle time. Expect this number to read slightly lower than Settings.
///
/// **What it is not.** It is a lagging lower bound in 15-minute steps, not a live counter.
/// The creature is designed around that: it reacts to "a quiet morning", never to a ticker.
/// Requires a real device; Family Controls does not track usage in the simulator.
@MainActor @Observable
final class ScreenTimeService {
    /// Current Family Controls authorization for this person.
    private(set) var status: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus

    /// Minutes spent ON the phone today, as last reported by the monitor extension.
    /// nil until authorized and the first threshold of the day has fired.
    private(set) var usedMinutes: Int?

    /// Hours on the phone today. Kept for the callers that think in hours.
    var usedHours: Double? { usedMinutes.map { Double($0) / 60 } }

    private let center = DeviceActivityCenter()

    /// Hours of today that have actually happened so far. The ceiling on any off-phone
    /// figure: you cannot have been off your phone longer than the day has existed.
    private var elapsedToday: Double {
        Double(ScreenTimeShare.minutesElapsedToday()) / 60
    }

    /// Hours off the phone so far today. Never more than the day has offered.
    var offScreenHours: Double? {
        guard let used = usedHours else { return nil }
        return max(0, min(elapsedToday, elapsedToday - used))
    }

    /// Under this much daily screen time reads as a good "off phone" day.
    let screenGoalHours: Double = 3

    /// True only when authorized AND a real figure has arrived.
    var available: Bool { status == .approved && usedMinutes != nil }

    /// Authorized, but no threshold has fired yet today.
    ///
    /// A normal state, not an error: the first one cannot arrive until 15 minutes of screen
    /// time have happened, and the system flushes the callback when it next wakes the
    /// extension. The tile says "counting" rather than claiming zero.
    var awaitingFirstReading: Bool { status == .approved && usedMinutes == nil }

    /// Whether today is still inside the off-phone budget. Measured against time USED, so
    /// a genuinely good morning reads as good in the morning.
    var hitGoal: Bool {
        guard let used = usedHours else { return false }
        return used <= screenGoalHours
    }

    /// How much of today's screen-time budget is still unspent, 0...1. Starts full and
    /// drains: a bar that begins empty every morning tells someone they are behind on a day
    /// they have not lived yet.
    var offScreenProgress: Double {
        guard let used = usedHours else { return 1 }
        return min(1, max(0, 1 - used / max(0.5, screenGoalHours)))
    }

    // MARK: Authorization

    /// Ask for Family Controls authorization, then start monitoring. Returns whether we are
    /// approved. Fails gracefully (false) with no entitlement or on the simulator.
    ///
    /// **Success is "the request did not throw", NOT a re-read of the status.**
    /// `requestAuthorization(for:)` throws on denial and returns normally on approval, and
    /// the status does not reliably reflect the grant by the time the await returns. This
    /// once told someone standing on a real device, having just tapped Allow, that the
    /// feature "needs Screen Time access, and a real device".
    @discardableResult
    func connect() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            status = .approved
            startMonitoring()
            refresh()
            return true
        } catch {
            status = AuthorizationCenter.shared.authorizationStatus
            refresh()
            return false
        }
    }

    /// Re-read status and today's figure without prompting (returning player).
    func resume() {
        status = AuthorizationCenter.shared.authorizationStatus
        if status == .approved { startMonitoring() }
        refresh()
    }

    /// Adopt whatever the extension has written for today.
    func refresh() {
        usedMinutes = ScreenTimeShare.usedMinutesToday()
    }

    // MARK: Monitoring

    /// Register (or re-register) the daily ladder.
    ///
    /// Called on every launch and foreground rather than once, on purpose. A monitored
    /// interval can end mid-day (a reboot, the system evicting the extension) and iOS will
    /// not restart it until the next midnight, which would freeze the number for the rest
    /// of the day. Re-registering also *heals* the day: every event is registered with
    /// `includesPastActivity`, so thresholds already crossed fire again in a burst and the
    /// missed usage is backfilled. `ScreenTimeShare.record` is idempotent, so the burst is
    /// harmless.
    func startMonitoring() {
        guard status == .approved else { return }
        // Midnight to 23:59, repeating. The floor for an interval is fifteen minutes and
        // the ceiling a week, so a day is comfortably legal.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in ScreenTimeLadder.steps {
            let threshold = DateComponents(minute: minutes)
            let event: DeviceActivityEvent
            if #available(iOS 17.4, *) {
                // `includesPastActivity` defaults to FALSE on 17.4+, a silent change from
                // earlier behaviour. Left at the default, a ladder registered at 3pm counts
                // nothing before 3pm, so "today" would start whenever the app happened to
                // launch.
                event = DeviceActivityEvent(threshold: threshold, includesPastActivity: true)
            } else {
                event = DeviceActivityEvent(threshold: threshold)
            }
            events[DeviceActivityEvent.Name(ScreenTimeLadder.eventName(minutes: minutes))] = event
        }
        let activity = DeviceActivityName(ScreenTimeLadder.activityName)
        // Stop first. iOS 18 stopped honouring the documented "startMonitoring overwrites
        // the previous schedule", and a re-register without this can silently do nothing.
        center.stopMonitoring([activity])
        do {
            try center.startMonitoring(activity, during: schedule, events: events)
        } catch {
            // Nothing to do from here: no entitlement, unauthorized, or the simulator.
            // `available` stays false and the UI keeps its honest "soon" state.
        }
    }

    #if DEBUG
    /// Dev only: fake an off-phone figure so the pillar renders in screenshots without a
    /// real device (Family Controls does not track usage in the simulator).
    func mock(usedHours hours: Double = 2) {
        status = .approved
        usedMinutes = Int(hours * 60)
    }
    #endif
}

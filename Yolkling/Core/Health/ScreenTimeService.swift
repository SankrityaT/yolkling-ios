import Foundation
import FamilyControls
import DeviceActivity

/// The "time off your phone" half of grow-by-living. Reads today's total screen
/// time through a DeviceActivityReport extension (privacy-blind: the extension
/// only ever sees opaque app tokens + durations, never what you looked at), and
/// turns it into "hours off the phone" that gently, additively feed the creature.
///
/// Requires Apple's Family Controls entitlement + a real device. On the simulator,
/// before authorization, or if the entitlement isn't granted yet, it stays gated
/// (`available == false`) and the home UI shows a soft "soon" pillar. The feature
/// is purely additive and self-gating, so the app ships correctly either way.
@MainActor @Observable
final class ScreenTimeService {
    /// Current Family Controls authorization for this person.
    private(set) var status: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus

    /// Hours spent ON the phone today, as measured by the report extension.
    /// nil until authorized and the extension has produced a figure.
    private(set) var usedHours: Double?

    /// Hours of today that have actually happened so far.
    ///
    /// The ceiling on any "off phone" figure. Without it the app was reporting a
    /// full 24 hours off the phone at 1am, which is both impossible and the kind of
    /// number that makes someone stop trusting every other number on the screen.
    private var elapsedToday: Double {
        let now = Date()
        return now.timeIntervalSince(Calendar.current.startOfDay(for: now)) / 3600
    }

    /// Hours off the phone so far today. Never more than the day has offered.
    var offScreenHours: Double? {
        guard let used = usedHours else { return nil }
        return max(0, min(elapsedToday, elapsedToday - used))
    }

    /// Under this much daily screen time reads as a good "off phone" day.
    let screenGoalHours: Double = 3

    /// True only when authorized AND we have a real number to show.
    var available: Bool { status == .approved && usedHours != nil }

    /// Whether today is still inside the off-phone budget.
    ///
    /// Measured against time USED, not time off. The old test was `off >= 21`, which
    /// only becomes achievable late in the day however little you touch the phone, so
    /// a genuinely good morning read as a failure until the evening.
    var hitGoal: Bool {
        guard let used = usedHours else { return false }
        return used <= screenGoalHours
    }

    /// 0...1 progress toward a full off-phone day. Always non-negative, so a heavy
    /// screen day can never subtract from the creature's vitality (WELLBEING.md:
    /// the yolk gets sleepy, never sick).
    /// How much of today's screen-time budget is still unspent, 0...1.
    ///
    /// Framed as budget remaining rather than hours accumulated, so it starts full and
    /// drains. A bar that begins empty every morning tells someone they are behind on a
    /// day they have not lived yet.
    var offScreenProgress: Double {
        guard let used = usedHours else { return 1 }
        return min(1, max(0, 1 - used / max(0.5, screenGoalHours)))
    }

    /// Ask for Family Controls authorization, then read the latest figure. Returns
    /// whether we're approved. Fails gracefully (false) with no entitlement/device.
    @discardableResult
    func connect() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            // No entitlement, declined, or unsupported (simulator) -> stay gated.
        }
        status = AuthorizationCenter.shared.authorizationStatus
        refresh()
        return status == .approved
    }

    /// Re-read status + the latest shared figure without prompting (returning player).
    func resume() {
        status = AuthorizationCenter.shared.authorizationStatus
        refresh()
    }

    /// Pull the newest off-phone figure the report extension wrote to the App Group.
    func refresh() {
        if let used = ScreenTimeShare.readUsedHours() { usedHours = used }
    }

    #if DEBUG
    /// Dev only: fake an off-phone figure so the pillar renders in screenshots
    /// without a real device (Family Controls does not run in the simulator).
    func mock(usedHours hours: Double = 2) {
        status = .approved
        usedHours = hours
    }
    #endif
}

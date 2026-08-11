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

    /// Hours spent OFF the phone today, published by the report extension via the
    /// App Group. nil until authorized and the extension has produced a figure.
    private(set) var offScreenHours: Double?

    /// Under this much daily screen time reads as a good "off phone" day.
    let screenGoalHours: Double = 3

    /// True only when authorized AND we have a real number to show.
    var available: Bool { status == .approved && offScreenHours != nil }

    /// Whether today clears the off-phone goal.
    var hitGoal: Bool {
        guard let off = offScreenHours else { return false }
        return off >= (24 - screenGoalHours)
    }

    /// 0...1 progress toward a full off-phone day. Always non-negative, so a heavy
    /// screen day can never subtract from the creature's vitality (WELLBEING.md:
    /// the yolk gets sleepy, never sick).
    var offScreenProgress: Double {
        guard let off = offScreenHours else { return 0 }
        let target = max(1, 24 - screenGoalHours)
        return min(1, max(0, off / target))
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
        if let off = ScreenTimeShare.readOffHours() { offScreenHours = off }
    }

    #if DEBUG
    /// Dev only: fake an off-phone figure so the pillar renders in screenshots
    /// without a real device (Family Controls does not run in the simulator).
    func mock(offHours: Double = 20) {
        status = .approved
        offScreenHours = offHours
    }
    #endif
}

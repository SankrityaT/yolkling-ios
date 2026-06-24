import Foundation

/// The "time off your phone" half of grow-by-living. Reading real usage needs Apple's
/// **Family Controls** entitlement + a **DeviceActivityReport** app-extension + a real
/// device (none of which exist in the simulator), so this is a deliberate stub.
///
/// Everything downstream (the home card pillar, and later the vitality calc) already
/// renders + reasons about it. The moment the entitlement is granted and a report
/// extension supplies a daily figure, flip `available` to true and fill
/// `offScreenHours` from the report. Nothing else has to change.
@MainActor @Observable
final class ScreenTimeService {
    /// Flip to `true` once the Family Controls entitlement + DeviceActivityReport
    /// extension are wired. Gated off until then so the UI shows a "soon" state.
    var available: Bool { false }

    /// Hours spent OFF the phone today. nil until a report extension provides it.
    private(set) var offScreenHours: Double?

    /// Under this much screen time reads as a good "off phone" day.
    let screenGoalHours: Double = 3

    /// Whether today clears the off-phone goal (false while gated).
    var hitGoal: Bool {
        guard available, let off = offScreenHours else { return false }
        return off >= (24 - screenGoalHours)
    }

    /// Will request Family Controls authorization once the entitlement exists:
    ///   try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    /// then a DeviceActivityReport extension feeds `offScreenHours`.
    func connect() async -> Bool { false }
}

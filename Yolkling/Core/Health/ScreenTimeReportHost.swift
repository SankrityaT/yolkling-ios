import SwiftUI
import DeviceActivity

extension DeviceActivityReport.Context {
    /// The single report we host: today's total activity, reduced to off-phone hours.
    static let totalActivity = Self("Total Activity")
}

/// Hosts a hidden `DeviceActivityReport` so the report extension actually runs and
/// writes today's off-phone figure into the App Group. Mount it 1x1 and invisible;
/// the app reads the number back via `ScreenTimeService.refresh()` on foreground.
///
/// Only worth mounting once the person has approved Family Controls; before that
/// the report has nothing to show and the pillar stays in its "soon" state.
struct ScreenTimeReportHost: View {
    private var filter: DeviceActivityFilter {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .day, for: Date())
            ?? DateInterval(start: Date().addingTimeInterval(-86_400), end: Date())
        return DeviceActivityFilter(segment: .daily(during: interval))
    }

    var body: some View {
        // Nearly invisible rather than invisible. DeviceActivityReport is rendered by the
        // system out of process, and a zero-opacity view is a strong hint to skip that
        // work entirely -- in which case makeConfiguration never runs, nothing is ever
        // written to the App Group, and the tile reads "counting" forever no matter how
        // often the app re-reads.
        //
        // 0.01 opacity over 2pt is indistinguishable on screen and keeps the view a real
        // participant in the hierarchy. Still untappable and still hidden from
        // VoiceOver, because it has nothing to show or say.
        DeviceActivityReport(.totalActivity, filter: filter)
            .frame(width: 2, height: 2)
            .opacity(0.01)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

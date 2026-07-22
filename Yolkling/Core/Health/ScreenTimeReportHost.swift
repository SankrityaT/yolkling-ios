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
        DeviceActivityReport(.totalActivity, filter: filter)
            .frame(width: 1, height: 1)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

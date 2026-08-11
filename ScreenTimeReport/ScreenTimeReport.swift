import DeviceActivity
import SwiftUI

/// The DeviceActivityReport extension. It runs in its own sandbox and receives the
/// device's activity as opaque tokens + durations only, never app identities or
/// content. It sums today's total on-screen time, derives "hours off the phone",
/// and hands that single aggregate back to the app through the App Group. Raw
/// usage never leaves this sandbox except as that one number.
@main
struct ScreenTimeReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { offHours in
            TotalActivityView(offHours: offHours)
        }
    }
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

/// Reduces the activity results to a single Double (off-phone hours) and publishes
/// it to the shared container for the main app.
struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (Double) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Double {
        var totalSeconds: TimeInterval = 0
        for await result in data {
            for await segment in result.activitySegments {
                totalSeconds += segment.totalActivityDuration
            }
        }
        let offHours = max(0, min(24, 24 - totalSeconds / 3600))
        ScreenTimeShare.write(offHours: offHours)
        return offHours
    }
}

/// Nothing needs to render: the host mounts this hidden. The value is delivered
/// via the App Group in `makeConfiguration`, not on screen.
struct TotalActivityView: View {
    let offHours: Double
    var body: some View { Color.clear }
}

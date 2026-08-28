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
        TotalActivityReport { usedHours in
            TotalActivityView(usedHours: usedHours)
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
        // Publish what was MEASURED (time on screen), not a derived "off" figure.
        //
        // This used to compute `24 - used` and publish that, which claimed a full 24
        // hours off the phone at 1am — while the person was holding the phone reading
        // it. You cannot have been off your phone longer than the day has existed. The
        // app derives the off-phone figure from elapsed time instead, so the number can
        // never exceed the part of the day that has actually happened.
        ScreenTimeShare.write(usedHours: totalSeconds / 3600)
        return totalSeconds / 3600
    }
}

/// Nothing needs to render: the host mounts this hidden. The value is delivered
/// via the App Group in `makeConfiguration`, not on screen.
struct TotalActivityView: View {
    let usedHours: Double
    var body: some View { Color.clear }
}

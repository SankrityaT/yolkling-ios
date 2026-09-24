import DeviceActivity
import Foundation
import os

/// The DeviceActivityMonitor extension: the only part of the Screen Time API that is
/// allowed to tell the app anything.
///
/// The system launches this out of process when a threshold the app registered is crossed.
/// Unlike the DeviceActivityReport extension, it is not in the read-only sandbox, so it can
/// write to the App Group — which is the whole reason the feature can work at all.
///
/// Keep every callback tiny and synchronous. The process is killed as soon as the call
/// returns (nothing async survives) and it runs under a ~6 MB memory limit, so there is no
/// networking, no images and no frameworks in here on purpose.
///
/// `nonisolated` on every override: DeviceActivityMonitor's methods are nonisolated, but
/// this project defaults new declarations to @MainActor (SWIFT_DEFAULT_ACTOR_ISOLATION),
/// which conflicts with the superclass unless said explicitly.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private nonisolated static let log = Logger(subsystem: "com.yolkling.ios", category: "screentime")

    nonisolated override init() {
        super.init()
    }

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // A new day's interval. Nothing to reset: storage is day-keyed, so today simply
        // starts empty. Prune old days while we are awake anyway.
        ScreenTimeShare.prune()
        Self.log.info("interval start \(activity.rawValue, privacy: .public)")
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        Self.log.info("interval end \(activity.rawValue, privacy: .public)")
    }

    /// Usage passed one of the thresholds the app registered.
    ///
    /// The event name carries the minute count, because the callback itself says only
    /// *which* event fired, never how much time has passed or when. `ScreenTimeShare.record`
    /// does the defending: highest wins, impossible values are refused.
    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                                     activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard let minutes = ScreenTimeLadder.minutes(fromEventName: event.rawValue) else { return }
        let total = ScreenTimeShare.record(minutes: minutes)
        Self.log.info("threshold \(minutes, privacy: .public)m, stored \(total, privacy: .public)m")
    }

    nonisolated override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    nonisolated override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    nonisolated override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name,
                                                             activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }
}

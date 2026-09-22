import DeviceActivity

/// The DeviceActivityMonitor extension. Unlike ScreenTimeReport (which renders a report
/// view on demand), this one runs in the background and gets called by the system when
/// a DeviceActivitySchedule the app registered starts, ends, or crosses a threshold the
/// app set via DeviceActivityCenter.startMonitoring. It has the same sandboxed, no-raw-
/// usage-data constraints as ScreenTimeReport.
///
/// Scaffold only: no schedule is registered from the app yet (that's a
/// DeviceActivityCenter.startMonitoring(_:during:events:) call on the app side), so
/// these callbacks won't fire until that's wired up. Filled in as each event the app
/// actually needs to react to gets built.
///
/// `nonisolated` on every override: DeviceActivityMonitor's own methods are nonisolated,
/// but this project defaults new declarations to @MainActor (SWIFT_DEFAULT_ACTOR_ISOLATION),
/// which conflicts with the superclass unless said explicitly.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    nonisolated override init() {
        super.init()
    }

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }

    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    nonisolated override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    nonisolated override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    nonisolated override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }
}

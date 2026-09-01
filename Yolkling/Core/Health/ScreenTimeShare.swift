import Foundation

/// The contract shared between the app (reader) and the DeviceActivityReport
/// extension (writer) over the App Group. The extension computes today's total
/// on-screen time privacy-blind (opaque tokens + durations only, never what you
/// looked at), derives "hours off the phone", and writes the single aggregate
/// here. The app reads it back to gently feed the creature. Compiled into BOTH
/// the app and the extension targets.
enum ScreenTimeShare {
    static let appGroup = "group.com.yolkling.ios"
    static let usedHoursKey = "yolk.screen.usedHours"
    static let updatedKey = "yolk.screen.updatedAt"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Extension writes the hours actually spent ON screen today, plus a timestamp.
    ///
    /// Deliberately the measured figure rather than a derived "hours off" one. The
    /// derivation depends on how much of the day has elapsed, which changes every
    /// minute; baking it in at write time is what produced "24h off phone" at 1am.
    static func write(usedHours: Double) {
        guard let d = defaults else { return }
        d.set(usedHours, forKey: usedHoursKey)
        d.set(Date().timeIntervalSince1970, forKey: updatedKey)
    }

    /// App reads today's on-screen hours, or nil if the extension hasn't run yet.
    /// Today's figure, or nil if it is stale.
    ///
    /// The freshness timestamp was written and never read, and `ScreenTimeService.refresh`
    /// only assigns when non-nil, so `usedHours` was sticky forever. Yesterday's 6 hours
    /// drove this morning's off-phone pillar: ~0 hours off after a full night's sleep,
    /// `hitGoal` false, and the progress bar starting drained — the exact "starts empty
    /// every morning" failure this subsystem was designed to avoid. An expired figure is
    /// no figure.
    static func readUsedHours() -> Double? {
        guard let d = defaults, d.object(forKey: usedHoursKey) != nil else { return nil }
        let stamp = d.double(forKey: updatedKey)
        guard stamp > 0,
              Calendar.current.isDateInToday(Date(timeIntervalSince1970: stamp))
        else { return nil }
        return d.double(forKey: usedHoursKey)
    }
}

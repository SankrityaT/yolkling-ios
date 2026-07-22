import Foundation

/// The contract shared between the app (reader) and the DeviceActivityReport
/// extension (writer) over the App Group. The extension computes today's total
/// on-screen time privacy-blind (opaque tokens + durations only, never what you
/// looked at), derives "hours off the phone", and writes the single aggregate
/// here. The app reads it back to gently feed the creature. Compiled into BOTH
/// the app and the extension targets.
enum ScreenTimeShare {
    static let appGroup = "group.com.Sankritya.Yolkling"
    static let offHoursKey = "yolk.screen.offHours"
    static let updatedKey = "yolk.screen.updatedAt"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Extension writes the latest off-phone hours (0...24) plus a timestamp.
    static func write(offHours: Double) {
        guard let d = defaults else { return }
        d.set(offHours, forKey: offHoursKey)
        d.set(Date().timeIntervalSince1970, forKey: updatedKey)
    }

    /// App reads the latest off-phone hours, or nil if the extension hasn't run yet.
    static func readOffHours() -> Double? {
        guard let d = defaults, d.object(forKey: offHoursKey) != nil else { return nil }
        return d.double(forKey: offHoursKey)
    }
}

import Foundation

/// The contract between the DeviceActivityMonitor extension (writer) and the app (reader).
///
/// **Why a ladder of thresholds rather than a total.** The Screen Time API will not hand
/// any app a number for how long the phone has been used. The `DeviceActivityReport`
/// extension can compute one but runs in a read-only sandbox: its App Group writes, files
/// and network are all silently dropped, by design, so the figure can never leave it. That
/// is what the first version of this feature tried to do, and why the tile read "counting"
/// forever on every device.
///
/// A `DeviceActivityMonitor` extension is NOT sandboxed that way, but it is only ever told
/// "usage passed N minutes" for thresholds registered in advance. So the app registers a
/// ladder of them, the extension records the highest one that has fired today, and today's
/// usage is known to the nearest step.
///
/// **Everything here is defensive, because the callbacks are not a tidy stream:**
/// - Day-keyed, so an event the system flushes after midnight lands in the day it belongs
///   to instead of inflating this morning.
/// - High-water mark, never `+=`: events arrive out of order, batched, and sometimes twice.
/// - Capped by the clock: usage cannot exceed the minutes the day has actually had. This
///   one line is what neutralises the iOS 26 bug where thresholds fire on an idle phone.
// `nonisolated`: this is the one type both the app and the DeviceActivityMonitor extension
// compile. The extension's callbacks are nonisolated, and the project defaults new
// declarations to @MainActor, so without this the extension cannot call any of it.
nonisolated enum ScreenTimeShare {
    /// The App Group belongs to ONE team, so a Dev build (signed with a personal team, to
    /// run on a device without being on the shipping team) cannot join the shipping group
    /// and has its own. Kept in step with YOLK_APP_GROUP in project.yml, which is what the
    /// entitlements use.
#if YOLK_DEV
    static let appGroup = "group.com.sankiii.yolkdev"
#else
    static let appGroup = "group.com.yolkling.ios"
#endif

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// `usage.2026-09-24` → minutes. Keyed by day so nothing needs a midnight reset and a
    /// late arrival cannot corrupt today.
    static func key(for date: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "usage.%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Minutes of the day that have actually happened. The ceiling on any claim.
    static func minutesElapsedToday(_ now: Date = .now) -> Int {
        Int(now.timeIntervalSince(Calendar.current.startOfDay(for: now)) / 60)
    }

    /// Record a threshold the system says has been crossed. Returns the stored total.
    ///
    /// Rejects the impossible rather than trusting it: a threshold claiming more minutes
    /// than the day has had is either a replayed event from yesterday or the iOS 26
    /// idle-device bug, and believing it would tell someone they had been on their phone
    /// for twelve hours before lunch.
    @discardableResult
    static func record(minutes: Int, now: Date = .now) -> Int {
        guard let d = defaults, minutes > 0 else { return usedMinutesToday(now) ?? 0 }
        let k = key(for: now)
        let current = d.integer(forKey: k)
        guard minutes <= minutesElapsedToday(now) + 2 else { return current }   // small clock slack
        if minutes > current { d.set(minutes, forKey: k) }
        d.set(Date().timeIntervalSince1970, forKey: "usage.updatedAt")
        return max(current, minutes)
    }

    /// Today's on-screen minutes as last reported, or nil if nothing has been recorded yet.
    ///
    /// nil is a real state and a different one from zero: it means the extension has not
    /// reported anything today, which is what "counting" on the tile means. Zero would be
    /// a claim that the phone has not been touched.
    static func usedMinutesToday(_ now: Date = .now) -> Int? {
        guard let d = defaults else { return nil }
        let k = key(for: now)
        guard d.object(forKey: k) != nil else { return nil }
        return min(d.integer(forKey: k), minutesElapsedToday(now))
    }

    /// Drop keys older than a week, so a year of daily keys does not accumulate.
    static func prune(before days: Int = 7, now: Date = .now) {
        guard let d = defaults else { return }
        let keep = Set((0...days).map { key(for: now.addingTimeInterval(TimeInterval(-86_400 * $0))) })
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("usage.20") && !keep.contains(k) {
            d.removeObject(forKey: k)
        }
    }
}

/// The threshold ladder, shared by the app (which registers it) and the extension (which
/// reads the minute count back out of the event name).
nonisolated enum ScreenTimeLadder {
    /// One activity holds the whole ladder. The documented cap of twenty is on *activities*
    /// monitored at once, not on events within one, so this stays comfortably inside it.
    static let activityName = "yolk.daily.usage"

    /// Fifteen minutes is the granularity the creature actually needs: it reacts to "a
    /// quiet morning" or "a heavy afternoon", never to a live ticker. Coarse steps also
    /// mean fewer events, and the system has been observed to fail registration silently
    /// when a ladder gets very long.
    static let stepMinutes = 15
    /// Twelve hours of screen time is past any figure the creature responds to.
    static let ceilingMinutes = 12 * 60

    static var steps: [Int] { Array(stride(from: stepMinutes, through: ceilingMinutes, by: stepMinutes)) }

    static func eventName(minutes: Int) -> String { "yolk.usage.\(minutes)" }

    /// The minute count carried by an event name, or nil if it is not one of ours.
    static func minutes(fromEventName name: String) -> Int? {
        guard name.hasPrefix("yolk.usage.") else { return nil }
        return Int(name.dropFirst("yolk.usage.".count))
    }
}

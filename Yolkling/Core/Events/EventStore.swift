import Foundation
import Observation

/// Live seasons, and the cache that keeps them from vanishing.
///
/// The last good response is persisted deliberately. A season is a promise with a clock
/// on it — if the network hiccups mid-season and the UI quietly reverts to "no season
/// running", the app has silently taken something away from someone. Cached windows are
/// self-limiting anyway: they expire on their own end date, so stale data can't keep a
/// finished season alive.
@MainActor @Observable
final class EventStore {
    private(set) var events: [SeasonalEvent] = []
    private(set) var loading = false

    private let client = SupabaseClient.shared
    private let userID: String

    init(userID: String) {
        self.userID = userID
        events = Self.cached()
        SeasonWindows.publish(Self.windows(events))
    }

    /// Seasons whose window contains now. Guards against a cached season outliving its
    /// own end date.
    var running: [SeasonalEvent] {
        events.filter { $0.window?.contains(Date()) == true }
    }

    /// The one to feature. Soonest to end — that's the one with real urgency.
    var featured: SeasonalEvent? {
        running.min { ($0.daysLeft ?? .max) < ($1.daysLeft ?? .max) }
    }

    func refresh() async {
        loading = true
        let fresh = await client.activeEvents(userID: userID)
        loading = false
        // nil means the call FAILED; [] means the server genuinely has nothing running.
        // Collapsing those two into an empty array would let one dropped request wipe a
        // live season off the screen.
        guard let fresh else { return }
        events = fresh
        Self.cache(fresh)
        SeasonWindows.publish(Self.windows(fresh))
    }

    @discardableResult
    func join(_ event: SeasonalEvent) async -> [String] {
        let granted = await client.joinEvent(userID: userID, eventID: event.id)
        await refresh()
        return granted
    }

    // MARK: Cache

    private static let key = "yolk.events.cache"

    private static func cached() -> [SeasonalEvent] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SeasonalEvent].self, from: data)) ?? []
    }

    private static func cache(_ events: [SeasonalEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Flatten to the plain payloadID → window map that `SeasonWindows` (widget-safe)
    /// can consume without knowing what a SeasonalEvent is.
    private static func windows(_ events: [SeasonalEvent]) -> [String: DateInterval] {
        var out: [String: DateInterval] = [:]
        for e in events { if let w = e.window { out[e.payloadID] = w } }
        return out
    }
}

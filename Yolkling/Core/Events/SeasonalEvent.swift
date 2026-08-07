import Foundation

/// A season: a species set in bloom for a bounded window.
///
/// The window is server-driven so a season can open and close without shipping a build.
/// The ART is not — all content is compiled-in Swift, so `payloadID` always points at
/// something this binary already knows how to draw. A season schedules existing content;
/// it cannot introduce new content.
struct SeasonalEvent: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let kind: String
    let payload_id: String
    let title: String
    let blurb: String
    let starts_at: String
    let ends_at: String
    let requires_entitlement: String?
    let joined: Bool

    var payloadID: String { payload_id }

    /// Plus-only seasons exist so a subscription has something time-anchored attached.
    var requiresPlus: Bool { requires_entitlement == "plus" }

    var window: DateInterval? {
        guard let s = Self.date(starts_at), let e = Self.date(ends_at), e > s else { return nil }
        return DateInterval(start: s, end: e)
    }

    var daysLeft: Int? {
        guard let w = window else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: w.end).day
    }

    /// Postgres timestamptz comes back in a couple of shapes depending on fractional
    /// seconds, so try both rather than silently failing to parse a live season.
    private static func date(_ s: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: s) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let d = plain.date(from: s) { return d }
        // PostgREST sometimes returns "2026-08-07 12:00:00+00" with a space.
        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
        return fallback.date(from: s)
    }
}

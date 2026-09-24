import Foundation

/// The contract shared between the app (writer) and the widget (reader) over the
/// App Group. Pure value type; carries the same RoomSnapshot friends use to render
/// a room, plus the yolk's name.
enum WidgetShare {
    /// The App Group belongs to ONE team, so a Dev build (signed with a personal team, to
    /// run on a device without being on the shipping team) cannot join the shipping group
    /// and has its own. Kept in step with YOLK_APP_GROUP in project.yml, which is what the
    /// entitlements use.
#if YOLK_DEV
    static let appGroup = "group.com.sankiii.yolkdev"
#else
    static let appGroup = "group.com.yolkling.ios"
#endif
    static let key = "yolk.widget.snapshot"
    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }
}

struct WidgetSnapshot: Codable, Sendable {
    var name: String
    var room: RoomSnapshot

    /// The latest snapshot the app published, or nil if none yet.
    static func read() -> WidgetSnapshot? {
        guard let data = WidgetShare.defaults?.data(forKey: WidgetShare.key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Persist to the shared container for the widget to read.
    func write() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        WidgetShare.defaults?.set(data, forKey: WidgetShare.key)
    }

    /// Forget the published creature. Called on account deletion: the App Group survives
    /// the SwiftData wipe, so without this the deleted yolk kept rendering on the home
    /// screen by name, indefinitely, on a screen the person can still see. That makes a
    /// data-deletion promise visibly untrue.
    static func clear() {
        WidgetShare.defaults?.removeObject(forKey: WidgetShare.key)
    }
}

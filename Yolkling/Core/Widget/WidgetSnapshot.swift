import Foundation

/// The contract shared between the app (writer) and the widget (reader) over the
/// App Group. Pure value type; carries the same RoomSnapshot friends use to render
/// a room, plus the yolk's name.
enum WidgetShare {
    static let appGroup = "group.com.Sankritya.Yolkling"
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
}

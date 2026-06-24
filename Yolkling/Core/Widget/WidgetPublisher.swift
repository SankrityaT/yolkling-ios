import WidgetKit

/// Writes the current look to the App Group and asks the widget to reload. Best-effort.
enum WidgetPublisher {
    static func publish(name: String, room: RoomSnapshot) {
        WidgetSnapshot(name: name, room: room).write()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

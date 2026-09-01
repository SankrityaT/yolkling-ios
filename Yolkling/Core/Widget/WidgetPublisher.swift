import WidgetKit

/// Writes the current look to the App Group and asks the widget to reload. Best-effort.
enum WidgetPublisher {
    static func publish(name: String, room: RoomSnapshot) {
        WidgetSnapshot(name: name, room: room).write()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Ask the widget to redraw without publishing anything. Used after clearing the
    /// snapshot on account deletion, so the home screen stops showing a creature that
    /// no longer exists.
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

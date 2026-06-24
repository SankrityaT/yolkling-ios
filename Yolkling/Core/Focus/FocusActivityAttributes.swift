import ActivityKit
import Foundation

/// Shared between the app (which starts/ends the activity) and the widget
/// extension (which renders it). Compiled into both targets.
struct FocusActivityAttributes: ActivityAttributes {
    /// Dynamic content. `endDate` drives the auto-counting-down timer.
    struct ContentState: Codable, Hashable {
        var endDate: Date
    }

    /// Static for the whole session.
    var creatureName: String
    var colorHex: Int
}

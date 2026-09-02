import SwiftUI

@main
struct YolklingWatchApp: App {
    @State private var sync = WatchSyncModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(sync: sync)
        }
    }
}

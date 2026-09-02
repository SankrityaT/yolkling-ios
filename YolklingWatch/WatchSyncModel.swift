import Foundation
import Observation
import WatchConnectivity
import YolklingCore

/// Receives the phone's `WatchCreatureSnapshot` over WatchConnectivity and keeps
/// the last one in UserDefaults, so the creature appears immediately on launch
/// instead of waiting for the phone. Counterpart of the app's `WatchPublisher`.
@Observable
final class WatchSyncModel: NSObject {
    private(set) var snapshot: WatchCreatureSnapshot?

    private static let cacheKey = "yolk.watch.lastSnapshot"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey) {
            snapshot = WatchCreatureSnapshot.decoded(from: data)
        }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(_ data: Data) {
        guard let snap = WatchCreatureSnapshot.decoded(from: data) else { return }
        snapshot = snap
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }
}

extension WatchSyncModel: WCSessionDelegate {
    // Delegate callbacks arrive off the main thread; extract the (Sendable) payload
    // there, then hop to the main actor to publish it to SwiftUI.
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Whatever the phone sent while this app was closed is already waiting in
        // receivedApplicationContext once activation completes.
        guard let data = session.receivedApplicationContext[WatchCreatureSnapshot.contextKey] as? Data else { return }
        Task { @MainActor in self.apply(data) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[WatchCreatureSnapshot.contextKey] as? Data else { return }
        Task { @MainActor in self.apply(data) }
    }
}

import Foundation
import WatchConnectivity
import YolklingCore

/// Pushes the creature's current state to the Apple Watch. Best-effort, same
/// spirit as `WidgetPublisher` next door — but where the widget shares a device
/// (App Group), the watch is a SEPARATE device, so state crosses over
/// WatchConnectivity instead. `updateApplicationContext` keeps only the latest
/// snapshot and delivers it even while the watch app is closed, which is exactly
/// the "here is the current look" semantic the creature needs.
final class WatchPublisher: NSObject {
    static let shared = WatchPublisher()

    /// A snapshot that arrived before the session finished activating; sent from
    /// the activation callback. Only the newest one matters.
    private var pending: WatchCreatureSnapshot?

    func publish(_ snapshot: WatchCreatureSnapshot) {
        guard WCSession.isSupported() else { return }   // iPad etc.
        let session = WCSession.default
        session.delegate = self
        if session.activationState == .activated {
            send(snapshot)
        } else {
            pending = snapshot
            session.activate()
        }
    }

    private func send(_ snapshot: WatchCreatureSnapshot) {
        let session = WCSession.default
        guard session.isPaired, session.isWatchAppInstalled,
              let data = snapshot.encoded() else { return }
        // Throws only for setup problems (not paired / not activated), which the
        // guards above already cover; a delivery failure is retried by the system.
        try? session.updateApplicationContext([WatchCreatureSnapshot.contextKey: data])
    }
}

extension WatchPublisher: WCSessionDelegate {
    // Delegate callbacks arrive off the main thread; hop back before touching state.
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            guard activationState == .activated, let snapshot = self.pending else { return }
            self.pending = nil
            self.send(snapshot)
        }
    }

    // Required on iOS for the multiple-watch handoff dance.
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}

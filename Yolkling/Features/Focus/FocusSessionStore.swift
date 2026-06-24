import SwiftUI
import UserNotifications
import ActivityKit
import Observation

/// Drives a focus session. End-date based (suspension-proof) with the honest
/// phone-down heuristic: foreground or locked = focusing; switching to another
/// app ends the session. See docs/FOCUS.md.
@MainActor
@Observable
final class FocusSessionStore {
    enum Phase: Equatable { case idle, running, completed, ended }

    private(set) var phase: Phase = .idle
    var durationMinutes: Int = 25
    private(set) var endDate: Date?

    // Set by the view so the Live Activity can show the creature's name + colour.
    var creatureName: String = "your yolkling"
    var creatureColorHex: Int = 0xFFC23B

    private var locked = false
    private var awayCheck: Task<Void, Never>?
    private var activity: Activity<FocusActivityAttributes>?
    private let notifID = "yolk-focus-done"

    func start(_ minutes: Int) {
        durationMinutes = minutes
        endDate = Date().addingTimeInterval(Double(minutes) * 60)
        phase = .running
        scheduleNotification()
        startActivity()
    }

    func cancel() { finish(.ended) }
    func complete() { if phase == .running { finish(.completed) } }
    func reset() { phase = .idle; endDate = nil }

    func remaining(at now: Date) -> TimeInterval { max(0, (endDate ?? now).timeIntervalSince(now)) }

    func progress(at now: Date) -> Double {
        guard let end = endDate else { return 0 }
        let total = Double(durationMinutes) * 60
        return total <= 0 ? 1 : min(1, max(0, 1 - end.timeIntervalSince(now) / total))
    }

    // MARK: The honest heuristic (scenePhase + device lock)

    func sceneBecameActive() {
        awayCheck?.cancel()
        if phase == .running, let end = endDate, Date() >= end { finish(.completed) }
    }

    func sceneBackgrounded() {
        guard phase == .running else { return }
        awayCheck?.cancel()
        awayCheck = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.9))   // let a lock notification arrive
            guard let self else { return }
            if self.phase == .running && !self.locked { self.finish(.ended) }   // switched apps
        }
    }

    func setLocked(_ value: Bool) {
        locked = value
        if value { awayCheck?.cancel() }   // phone locked = genuinely down = still focusing
    }

    private func finish(_ p: Phase) {
        phase = p
        endDate = nil
        awayCheck?.cancel()
        cancelNotification()
        endActivity()
    }

    // MARK: Live Activity

    private func startActivity() {
        guard let end = endDate, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = FocusActivityAttributes(creatureName: creatureName, colorHex: creatureColorHex)
        let state = FocusActivityAttributes.ContentState(endDate: end)
        activity = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: end))
    }

    private func endActivity() {
        activity = nil
        Task {
            for current in Activity<FocusActivityAttributes>.activities {
                await current.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: Local notification

    private func scheduleNotification() {
        guard let end = endDate else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = "focus done"
        content.body = "your yolkling rested while you were away. come say hi."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: notifID, content: content, trigger: trigger))
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifID])
    }
}

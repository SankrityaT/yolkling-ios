import UserNotifications
import Foundation

/// The single external trigger: one gentle, user-scheduled daily hello. No badges,
/// no "you are losing your streak" guilt, easy to turn off. We schedule a rolling
/// week ahead with rotating warm copy and top it up on each launch, so a lapsed
/// user is never nagged for long (see docs/MONETIZATION.md, guardrail 4).
enum YolkNotifications {
    private static let enabledKey = "yolk.dailyHello"
    private static let hourKey = "yolk.dailyHelloHour"
    private static let minKey = "yolk.dailyHelloMin"
    private static let idPrefix = "yolk.daily"
    private static let window = 7

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var hour: Int { UserDefaults.standard.object(forKey: hourKey) as? Int ?? 9 }
    static var minute: Int { UserDefaults.standard.object(forKey: minKey) as? Int ?? 0 }

    /// Warm, low-pressure lines. No urgency, no shame, no numbers.
    private static let lines: [(String, String)] = [
        ("your yolk is up", "it stretched, blinked, and looked around for you."),
        ("a little hello", "your yolk is pottering about. come say hi when you can."),
        ("soft morning", "no rush. your yolk just wanted to see your face today."),
        ("psst", "your yolk found a sunny spot and saved you a seat."),
        ("whenever you're ready", "your yolk is here, cozy and unbothered. drop by if you like."),
        ("a small wave", "nothing urgent. your yolk hopes today is gentle on you."),
        ("still here", "your yolk has been doodling and humming. it would love a visit."),
    ]

    /// Ask permission and turn the daily hello on. Returns false if denied.
    @discardableResult
    static func enable(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else {
            UserDefaults.standard.set(false, forKey: enabledKey)
            return false
        }
        UserDefaults.standard.set(true, forKey: enabledKey)
        UserDefaults.standard.set(hour, forKey: hourKey)
        UserDefaults.standard.set(minute, forKey: minKey)
        schedule(hour: hour, minute: minute)
        return true
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        clear()
    }

    /// Top up the rolling window on launch, only if the user opted in.
    static func reschedule() {
        guard isEnabled else { return }
        schedule(hour: hour, minute: minute)
    }

    private static func clear() {
        let ids = (0..<window).map { "\(idPrefix).\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func schedule(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        clear()
        let cal = Calendar.current
        for i in 0..<window {
            guard let day = cal.date(byAdding: .day, value: i + 1, to: cal.startOfDay(for: Date())) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            let line = lines[i % lines.count]
            let content = UNMutableNotificationContent()
            content.title = line.0
            content.body = line.1
            content.sound = .default               // deliberately no badge number
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "\(idPrefix).\(i)", content: content, trigger: trigger),
                       withCompletionHandler: nil)
        }
    }
}

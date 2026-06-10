import Foundation
import UserNotifications

final class NotificationService: NotificationServicing {
    private let center: UNUserNotificationCenter
    private let breakReminderIdentifier = "break-reminder"

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else { return }

            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    func scheduleBreakReminder(after minutes: Int) {
        let clampedMinutes = max(minutes, 1)
        let timeInterval = TimeInterval(clampedMinutes) * 60

        center.removePendingNotificationRequests(withIdentifiers: [breakReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Break reminder"
        content.body = "Time to take a break."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, timeInterval), repeats: true)
        let request = UNNotificationRequest(identifier: breakReminderIdentifier, content: content, trigger: trigger)

        center.add(request)
    }

    func clearBreakReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [breakReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [breakReminderIdentifier])
    }
}


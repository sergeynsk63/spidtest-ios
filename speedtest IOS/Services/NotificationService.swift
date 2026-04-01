import UserNotifications
import UIKit

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermissionAndSchedule() {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            self.scheduleIfNeeded()
        }
    }

    private func scheduleIfNeeded() {
        let key = AppConstants.Notifications.scheduledKey
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        for message in AppConstants.Notifications.messages {
            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = .default
            content.userInfo = ["url": AppConstants.promoURL]

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(message.delayHours * 3600),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: message.id,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    func handleNotificationTap() {
        guard let url = URL(string: AppConstants.promoURL) else { return }
        UIApplication.shared.open(url)
    }
}

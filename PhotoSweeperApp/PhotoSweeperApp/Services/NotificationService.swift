import Foundation
import UserNotifications
import PhotoSweeperCore

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Request notification authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            print("Notification authorization granted: \(granted)")
        }
    }

    /// Send notification when scan completes
    func sendScanCompletedNotification(processedCount: Int, savings: Int64 = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Analyse terminée"

        if savings > 0 {
            content.body = "Scan de \(processedCount) photos terminé — prêts à libérer \(Sweeper.formatBytes(savings))"
        } else {
            content.body = "Scan de \(processedCount) photos terminé"
        }

        content.sound = .default
        content.badge = 1

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "scan-completed",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    /// Clear all notifications
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

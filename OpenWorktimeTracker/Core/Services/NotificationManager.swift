import Foundation
import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.openworktimetracker.app", category: "Notifications")

/// Sends the system notifications a Workday raises: Notification Thresholds
/// and the new-day notice. NotificationManager is the production adapter.
protocol WorkdayNotificationSending {
    func sendThresholdNotification(_ threshold: NotifiedThreshold, hours: Double)
    func sendNewDayNotification()
}

final class NotificationManager: WorkdayNotificationSending {

    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permissions

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                logger.error("Notification permission error: \(error.localizedDescription)")
            }
            if !granted {
                logger.warning("Notification permission denied by user")
            }
        }
    }

    // MARK: - Threshold Notifications

    func sendThresholdNotification(_ threshold: NotifiedThreshold, hours: Double) {
        let content = UNMutableNotificationContent()

        switch threshold {
        case .normal:
            content.title = String(localized: "notification.normal.title")
            content.body = String(format: String(localized: "notification.normal.body"), hours)

        case .critical:
            content.title = String(localized: "notification.critical.title")
            content.body = String(
                format: String(localized: "notification.critical.body"), hours)

        case .milestone:
            content.title = String(localized: "notification.milestone.title")
            content.body = String(format: String(localized: "notification.milestone.body"), hours)

        default:
            logger.error("No notification for unknown Threshold: \(threshold.rawValue)")
            return
        }

        content.sound = .default
        content.interruptionLevel = .active

        let request = UNNotificationRequest(
            identifier: "threshold-\(threshold.rawValue)",
            content: content,
            trigger: nil  // Deliver immediately
        )
        center.add(request) { error in
            if let error {
                logger.error("Failed to add notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - New Day Notification

    func sendNewDayNotification() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.newDay.title")
        content.body = String(localized: "notification.newDay.body")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "new-day-\(Date().dateString)",
            content: content,
            trigger: nil
        )
        center.add(request) { error in
            if let error {
                logger.error("Failed to add notification: \(error.localizedDescription)")
            }
        }
    }
}

import Foundation
import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.openworktimetracker.app", category: "Notifications")

final class NotificationManager {

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

    func sendThresholdNotification(type: ThresholdType) {
        let content = UNMutableNotificationContent()

        switch type {
        case .normal(let hours):
            content.title = String(localized: "notification.normal.title")
            content.body = String(format: String(localized: "notification.normal.body"), hours)
            content.sound = .default

        case .critical(let hours):
            content.title = String(localized: "notification.critical.title")
            content.body = String(
                format: String(localized: "notification.critical.body"), hours)
            content.sound = .default

        case .milestone(let hours):
            content.title = String(localized: "notification.milestone.title")
            content.body = String(format: String(localized: "notification.milestone.body"), hours)
            content.sound = .default
        }

        content.interruptionLevel = .active

        let request = UNNotificationRequest(
            identifier: "threshold-\(type.identifier)",
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

    enum ThresholdType {
        case normal(hours: Double)
        case critical(hours: Double)
        case milestone(hours: Double)

        var identifier: String {
            switch self {
            case .normal: return "normal"
            case .critical: return "critical"
            case .milestone: return "milestone"
            }
        }
    }
}

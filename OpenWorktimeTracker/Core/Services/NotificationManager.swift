import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permissions

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Threshold Notifications

    func sendThresholdNotification(type: ThresholdType) {
        let content = UNMutableNotificationContent()

        switch type {
        case .normal(let hours):
            content.title = String(localized: "notification.normal.title")
            content.body = String(format: String(localized: "notification.normal.body"), hours)
            content.sound = UNNotificationSound.default

        case .critical(let hours):
            content.title = String(localized: "notification.critical.title")
            content.body = String(
                format: String(localized: "notification.critical.body"), hours)
            content.sound = .defaultCritical

        case .milestone(let hours):
            content.title = String(localized: "notification.milestone.title")
            content.body = String(format: String(localized: "notification.milestone.body"), hours)
            content.sound = .defaultCriticalSound
        }

        content.interruptionLevel = type.interruptionLevel

        let request = UNNotificationRequest(
            identifier: "threshold-\(type.identifier)",
            content: content,
            trigger: nil  // Deliver immediately
        )
        center.add(request)
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
        center.add(request)
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

        var interruptionLevel: UNNotificationInterruptionLevel {
            switch self {
            case .normal: return .active
            case .critical: return .timeSensitive
            case .milestone: return .critical
            }
        }
    }
}

extension UNNotificationSound {
    static let defaultCriticalSound = UNNotificationSound.defaultCritical
}

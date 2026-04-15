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
            content.title = "Normale Arbeitszeit erreicht"
            content.body = String(format: "Du hast %.1f Stunden gearbeitet. Feierabend?", hours)
            content.sound = .default

        case .critical(let hours):
            content.title = "Kritische Arbeitszeit!"
            content.body = String(
                format: "Du arbeitest seit %.1f Stunden. Du solltest jetzt gehen!", hours)
            content.sound = .defaultCritical

        case .milestone(let hours):
            content.title = "Maximum erreicht!"
            content.body = String(format: "%.1f Stunden Arbeitszeit. Sofort aufhören!", hours)
            content.sound = .defaultCritical
        }

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
        content.title = "Neuer Arbeitstag"
        content.body = "Guten Morgen! Dein Arbeitstag wird jetzt erfasst."
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
    }
}

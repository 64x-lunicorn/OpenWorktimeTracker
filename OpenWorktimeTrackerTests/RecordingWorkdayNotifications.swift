import Foundation

@testable import OpenWorktimeTracker

/// Test double for `WorkdayNotificationSending`. Records every system
/// notification WorkdayManager asks for, so tests assert on what would have
/// been delivered without touching UserNotifications.
final class RecordingWorkdayNotifications: WorkdayNotificationSending {

    private(set) var thresholds: [NotificationManager.ThresholdType] = []
    private(set) var newDayCount = 0

    /// The kinds of Notification Thresholds sent, in order.
    var thresholdIdentifiers: [String] { thresholds.map(\.identifier) }

    func sendThresholdNotification(type: NotificationManager.ThresholdType) {
        thresholds.append(type)
    }

    func sendNewDayNotification() {
        newDayCount += 1
    }
}

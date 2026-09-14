import Foundation

@testable import OpenWorktimeTracker

/// Test double for `WorkdayNotificationSending`. Records every system
/// notification WorkdayManager asks for, so tests assert on what would have
/// been delivered without touching UserNotifications.
final class RecordingWorkdayNotifications: WorkdayNotificationSending {

    /// The Notification Thresholds sent, in order.
    private(set) var thresholds: [NotifiedThreshold] = []
    private(set) var newDayCount = 0

    func sendThresholdNotification(_ threshold: NotifiedThreshold, hours: Double) {
        thresholds.append(threshold)
    }

    func sendNewDayNotification() {
        newDayCount += 1
    }
}

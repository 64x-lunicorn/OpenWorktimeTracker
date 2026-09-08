import Foundation

/// The Thresholds that fire a system notification as a Workday's Net Work Time
/// grows — normal, critical, and the milestone that also prompts to end the day.
///
/// Independent of the Threshold Ladder (which recolours); a user can set the two
/// to disagree on purpose.
struct NotificationThresholds {

    let normalHours: Double
    let criticalHours: Double
    let milestoneHours: Double
    let enabled: Bool

    /// Resolved from user settings.
    static func resolved(from defaults: UserDefaults = .standard) -> NotificationThresholds {
        NotificationThresholds(
            normalHours: defaults.object(forKey: AppSettingsKey.normalNotificationHours)
                as? Double ?? AppDefaults.normalNotificationHours,
            criticalHours: defaults.object(forKey: AppSettingsKey.criticalNotificationHours)
                as? Double ?? AppDefaults.criticalNotificationHours,
            milestoneHours: defaults.object(forKey: AppSettingsKey.milestoneNotificationHours)
                as? Double ?? AppDefaults.milestoneNotificationHours,
            enabled: defaults.object(forKey: AppSettingsKey.notificationsEnabled) as? Bool
                ?? AppDefaults.notificationsEnabled
        )
    }
}

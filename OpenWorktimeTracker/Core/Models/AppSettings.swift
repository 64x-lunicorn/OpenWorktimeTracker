import Foundation

enum AppSettingsKey {
    static let orangeThresholdHours = "orangeThresholdHours"
    static let redThresholdHours = "redThresholdHours"
    static let breakAfter6hMinutes = "breakAfter6hMinutes"
    static let breakAfter9hMinutes = "breakAfter9hMinutes"
    static let notificationsEnabled = "notificationsEnabled"
    static let normalNotificationHours = "normalNotificationHours"
    static let criticalNotificationHours = "criticalNotificationHours"
    static let milestoneNotificationHours = "milestoneNotificationHours"
    static let launchAtLogin = "launchAtLogin"
    static let idleThresholdMinutes = "idleThresholdMinutes"
    static let logFolderBookmark = "logFolderBookmark"
    static let newDayStartHour = "newDayStartHour"
}

enum AppDefaults {
    static let orangeThresholdHours: Double = 8.0
    static let redThresholdHours: Double = 9.5
    static let breakAfter6hMinutes: Int = 30
    static let breakAfter9hMinutes: Int = 45
    static let notificationsEnabled: Bool = true
    static let normalNotificationHours: Double = 8.0
    static let criticalNotificationHours: Double = 9.83
    static let milestoneNotificationHours: Double = 10.0
    static let launchAtLogin: Bool = true
    static let idleThresholdMinutes: Int = 5
    static let newDayStartHour: Int = 4  // Before 4 AM is still "yesterday"
}

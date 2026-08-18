import XCTest

@testable import OpenWorktimeTracker

/// Assembly tests for the config WorkdayManager resolves itself: Notification
/// Thresholds and the new-day start hour, both via an injected `UserDefaults`
/// rather than the real `.standard` suite.
final class WorkdayManagerSettingsTests: XCTestCase {

    private func customSuite(_ name: String = #function) -> UserDefaults {
        let suiteName = "workday-manager-settings-tests-\(name)-\(UUID())"
        let suite = UserDefaults(suiteName: suiteName)!
        addTeardownBlock { suite.removePersistentDomain(forName: suiteName) }
        return suite
    }

    func testNotificationThresholdsResolvedFromInjectedDefaults() {
        let suite = customSuite()
        suite.set(6.5, forKey: AppSettingsKey.normalNotificationHours)
        suite.set(9.0, forKey: AppSettingsKey.criticalNotificationHours)
        suite.set(9.75, forKey: AppSettingsKey.milestoneNotificationHours)
        suite.set(false, forKey: AppSettingsKey.notificationsEnabled)

        let manager = WorkdayManager(defaults: suite)

        XCTAssertEqual(manager.notificationThresholds.normalHours, 6.5)
        XCTAssertEqual(manager.notificationThresholds.criticalHours, 9.0)
        XCTAssertEqual(manager.notificationThresholds.milestoneHours, 9.75)
        XCTAssertEqual(manager.notificationThresholds.enabled, false)
    }

    func testNotificationThresholdsFallBackToDefaults() {
        let manager = WorkdayManager(defaults: customSuite())

        XCTAssertEqual(manager.notificationThresholds.normalHours, AppDefaults.normalNotificationHours)
        XCTAssertEqual(
            manager.notificationThresholds.criticalHours, AppDefaults.criticalNotificationHours)
        XCTAssertEqual(
            manager.notificationThresholds.milestoneHours, AppDefaults.milestoneNotificationHours)
        XCTAssertEqual(manager.notificationThresholds.enabled, AppDefaults.notificationsEnabled)
    }

    func testNewDayStartHourResolvedFromInjectedDefaults() {
        let suite = customSuite()
        suite.set(6, forKey: AppSettingsKey.newDayStartHour)

        let manager = WorkdayManager(defaults: suite)

        XCTAssertEqual(manager.newDayStartHour, 6)
    }

    func testNewDayStartHourFallsBackToDefault() {
        let manager = WorkdayManager(defaults: customSuite())

        XCTAssertEqual(manager.newDayStartHour, AppDefaults.newDayStartHour)
    }
}

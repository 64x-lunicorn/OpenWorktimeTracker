import XCTest

@testable import OpenWorktimeTracker

/// The new-day notice, observed through WorkdayManager's notification seam.
final class WorkdayManagerNotificationTests: WorkdayManagerNotificationTestCase {

    func testStartingANewWorkdaySendsOneNewDayNotice() {
        startWorkday()

        XCTAssertEqual(notifications.newDayCount, 1)
        XCTAssertTrue(notifications.thresholds.isEmpty)
    }

    func testStartingANewWorkdayWithNotificationsDisabledSendsNoNotice() {
        defaults.set(false, forKey: AppSettingsKey.notificationsEnabled)

        startWorkday()

        XCTAssertEqual(notifications.newDayCount, 0)
    }

    func testResumingAnExistingWorkdayForTheSameDateSendsNoNotice() {
        startWorkday()
        XCTAssertEqual(notifications.newDayCount, 1)

        manager = makeManager()
        manager.startNewDay()
        manager.startNewDay()

        XCTAssertEqual(notifications.newDayCount, 0)
        XCTAssertEqual(manager.state, .running)
    }
}

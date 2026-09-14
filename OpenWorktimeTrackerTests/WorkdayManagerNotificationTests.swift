import XCTest

@testable import OpenWorktimeTracker

/// The new-day notice, observed through WorkdayManager's notification seam.
final class WorkdayManagerNotificationTests: XCTestCase {

    private var clock: ManualClock!
    private var store: InMemoryDailyLogStore!
    private var notifications: RecordingWorkdayNotifications!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        clock = ManualClock(now: Calendar.current.date(
            from: DateComponents(year: 2026, month: 9, day: 14, hour: 8))!)
        store = InMemoryDailyLogStore()
        notifications = RecordingWorkdayNotifications()
        let suiteName = "notification-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        self.defaults = defaults
        addTeardownBlock { defaults.removePersistentDomain(forName: suiteName) }
    }

    override func tearDown() {
        clock = nil
        store = nil
        notifications = nil
        defaults = nil
        super.tearDown()
    }

    private func makeManager() -> WorkdayManager {
        WorkdayManager(
            defaults: defaults, clock: clock, store: store,
            idleDetector: IdleDetector(clock: clock, idleTime: { 0 }),
            notifications: notifications)
    }

    func testStartingANewWorkdaySendsOneNewDayNotice() {
        defaults.set(true, forKey: AppSettingsKey.notificationsEnabled)

        makeManager().startNewDay()

        XCTAssertEqual(notifications.newDayCount, 1)
        XCTAssertTrue(notifications.thresholds.isEmpty)
    }

    func testStartingANewWorkdayWithNotificationsDisabledSendsNoNotice() {
        defaults.set(false, forKey: AppSettingsKey.notificationsEnabled)

        makeManager().startNewDay()

        XCTAssertEqual(notifications.newDayCount, 0)
    }

    func testResumingAnExistingWorkdayForTheSameDateSendsNoNotice() {
        defaults.set(true, forKey: AppSettingsKey.notificationsEnabled)
        makeManager().startNewDay()
        XCTAssertEqual(notifications.newDayCount, 1)

        let reloaded = makeManager()
        reloaded.startNewDay()
        reloaded.startNewDay()

        XCTAssertEqual(notifications.newDayCount, 1)
        XCTAssertEqual(reloaded.state, .running)
    }
}

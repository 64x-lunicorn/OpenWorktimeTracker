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

    func testThresholdsNotifiedByThePreviousVersionAreNotNotifiedAgain() throws {
        // A running Daily Log as the previous version wrote it, with every
        // Notification Threshold already notified.
        let dailyLog = """
            {
              "id": "3F2504E0-4F89-11D3-9A0C-0305E82C3301",
              "date": "2026-09-14",
              "startTime": "\(ISO8601DateFormatter().string(from: clock.now))",
              "status": "running",
              "manualPauseSeconds": 0,
              "idleDecisions": [],
              "notifiedThresholds": ["normal", "critical", "milestone"],
              "note": ""
            }
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        store.save(try decoder.decode(TimeEntry.self, from: Data(dailyLog.utf8)))
        let prompts = RecordingWorkdayPrompts()
        let manager = WorkdayManager(
            defaults: defaults, clock: clock, store: store,
            idleDetector: IdleDetector(clock: clock, idleTime: { 0 }),
            prompts: prompts, notifications: notifications)
        manager.evaluateWorkday()
        clock.now = clock.now.addingTimeInterval(12 * 3600)

        manager.tick()
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)

        XCTAssertEqual(manager.state, .running)
        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }
}

import XCTest

@testable import OpenWorktimeTracker

/// Notification Thresholds, driven only through `tick()`: the ManualClock
/// moves Net Work Time, the injected idle time controls recent activity, and
/// outcomes are read from the recording adapters and the Daily Log store.
final class WorkdayManagerNotificationThresholdTests: WorkdayManagerNotificationTestCase {

    private func count(_ threshold: NotifiedThreshold) -> Int {
        notifications.thresholds.filter { $0 == threshold }.count
    }

    // MARK: - Milestone

    func testCrossingTheMilestoneNotifiesOnceAndPromptsToEndTheDay() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)

        tick(atHours: 10)
        drainMainQueue()

        XCTAssertEqual(count(.milestone), 1)
        XCTAssertEqual(prompts.maxHoursPrompts, [10])
    }

    func testCrossingTheMilestoneWithNotificationsDisabledStillPromptsToEndTheDay() {
        defaults.set(false, forKey: AppSettingsKey.notificationsEnabled)
        startWorkday()

        tick(atHours: 10)
        drainMainQueue()

        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertEqual(prompts.maxHoursPrompts, [10])
    }

    func testFurtherTicksPastTheMilestoneNeitherNotifyNorPromptAgain() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)
        tick(atHours: 10)
        drainMainQueue()

        tick(atHours: 10 + 1.0 / 3600)
        tick(atHours: 11)
        drainMainQueue()

        XCTAssertEqual(count(.milestone), 1)
        XCTAssertEqual(prompts.maxHoursPrompts.count, 1)
    }

    func testTheMilestoneIsRecordedSoAReloadedManagerDoesNotNotifyOrPromptAgain() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)
        tick(atHours: 10)
        drainMainQueue()
        XCTAssertEqual(count(.milestone), 1)

        manager = makeManager()
        manager.evaluateWorkday()
        tick(atHours: 11)
        drainMainQueue()

        XCTAssertEqual(manager.state, .running)
        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }

    func testNoPromptWhenTheWorkdayIsPausedBeforeThePromptIsPresented() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)
        tick(atHours: 10)

        manager.pause()
        drainMainQueue()

        XCTAssertEqual(count(.milestone), 1)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }

    func testNoPromptWhenAnIdlePeriodIsPendingBeforeThePromptIsPresented() {
        manager = makeManager()
        manager.bootstrap()
        tick(atHours: 8)
        tick(atHours: 9)
        tick(atHours: 10)

        // A locked screen long enough to count as an Idle Period.
        manager.handleActivityEvent(.lock)
        clock.now = clock.now.addingTimeInterval(10 * 60)
        manager.handleActivityEvent(.unlock)
        XCTAssertEqual(prompts.periods.count, 1)
        drainMainQueue()

        XCTAssertEqual(count(.milestone), 1)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }

    func testTheMilestoneWaitsForRecentActivityAndFiresOnTheFirstTickItReturns() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)

        idleSeconds = 3600
        tick(atHours: 10)
        tick(atHours: 10.5)
        drainMainQueue()
        XCTAssertEqual(count(.milestone), 0)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)

        idleSeconds = 0
        tick(atHours: 10.5)
        drainMainQueue()

        XCTAssertEqual(count(.milestone), 1)
        XCTAssertEqual(prompts.maxHoursPrompts, [10.5])
    }

    // MARK: - Normal and critical

    func testCrossingNormalThenCriticalNotifiesEachOnce() {
        startWorkday()
        tick(atHours: 7.9)
        XCTAssertTrue(notifications.thresholds.isEmpty)

        tick(atHours: 8)
        tick(atHours: 8.5)
        XCTAssertEqual(notifications.thresholds, [.normal])

        tick(atHours: 9)
        tick(atHours: 9.5)
        XCTAssertEqual(notifications.thresholds, [.normal, .critical])
    }

    func testNormalAndCriticalAreNotNotifiedWhenNotificationsAreDisabled() {
        defaults.set(false, forKey: AppSettingsKey.notificationsEnabled)
        startWorkday()

        tick(atHours: 8)
        tick(atHours: 9)
        tick(atHours: 9.5)
        XCTAssertTrue(notifications.thresholds.isEmpty)

        // Positive control: the check does run on these ticks, because the
        // milestone still prompts.
        tick(atHours: 10)
        drainMainQueue()
        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertEqual(prompts.maxHoursPrompts, [10])
    }

    func testJumpingStraightPastCriticalNotifiesOnlyCritical() {
        // Decided 2026-09-14: only the highest crossed Threshold is reported;
        // normal is recorded as notified and never follows, even after a reload.
        startWorkday()

        tick(atHours: 9)
        XCTAssertEqual(notifications.thresholds, [.critical])

        tick(atHours: 9 + 1.0 / 3600)
        tick(atHours: 9.5)
        XCTAssertEqual(notifications.thresholds, [.critical])

        manager = makeManager()
        manager.evaluateWorkday()
        tick(atHours: 9.75)
        XCTAssertTrue(notifications.thresholds.isEmpty)
    }

    func testJumpingStraightPastTheMilestoneNotifiesOnlyTheMilestone() {
        // Decided 2026-09-14: only the highest crossed Threshold is reported;
        // critical and normal are recorded as notified and never follow, even
        // after a reload.
        startWorkday()

        tick(atHours: 10)
        XCTAssertEqual(notifications.thresholds, [.milestone])

        tick(atHours: 10 + 1.0 / 3600)
        tick(atHours: 11)
        drainMainQueue()
        XCTAssertEqual(notifications.thresholds, [.milestone])
        XCTAssertEqual(prompts.maxHoursPrompts, [10])

        manager = makeManager()
        manager.evaluateWorkday()
        tick(atHours: 11.5)
        drainMainQueue()
        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }

    func testJumpingPastTheMilestoneWithNotificationsDisabledStillRecordsTheLowerThresholds() {
        // Decided 2026-09-14: the milestone marks critical and normal as notified
        // even when nothing is sent, so enabling notifications later sends neither.
        defaults.set(false, forKey: AppSettingsKey.notificationsEnabled)
        startWorkday()
        tick(atHours: 10)
        drainMainQueue()
        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertEqual(prompts.maxHoursPrompts, [10])

        defaults.set(true, forKey: AppSettingsKey.notificationsEnabled)
        manager = makeManager()
        manager.evaluateWorkday()
        tick(atHours: 11)
        drainMainQueue()

        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }

    // MARK: - Daily Log

    func testNotifiedThresholdsSurviveAReloadFromTheSameStore() {
        startWorkday()
        tick(atHours: 8)
        XCTAssertEqual(notifications.thresholds, [.normal])

        manager = makeManager()
        manager.evaluateWorkday()
        tick(atHours: 8.5)
        XCTAssertTrue(notifications.thresholds.isEmpty)

        tick(atHours: 9)
        XCTAssertEqual(notifications.thresholds, [.critical])

        manager = makeManager()
        manager.evaluateWorkday()
        tick(atHours: 9.5)
        XCTAssertTrue(notifications.thresholds.isEmpty)
    }

    func testThresholdsNotifiedByThePreviousVersionAreNotNotifiedAgain() throws {
        // A running Daily Log as the previous version wrote it, with every
        // Notification Threshold already notified.
        let dailyLog = """
            {
              "id": "3F2504E0-4F89-11D3-9A0C-0305E82C3301",
              "date": "2026-09-14",
              "startTime": "\(ISO8601DateFormatter().string(from: start))",
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
        manager = makeManager()
        manager.evaluateWorkday()

        tick(atHours: 12)
        drainMainQueue()

        XCTAssertEqual(manager.state, .running)
        XCTAssertTrue(notifications.thresholds.isEmpty)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)
    }
}

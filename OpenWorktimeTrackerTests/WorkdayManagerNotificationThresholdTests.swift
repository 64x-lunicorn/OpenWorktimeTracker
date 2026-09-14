import XCTest

@testable import OpenWorktimeTracker

/// Notification Thresholds, driven only through `tick()`: the ManualClock
/// moves Net Work Time, the injected idle time controls recent activity, and
/// outcomes are read from the recording adapters and the Daily Log store.
///
/// Auto Break is configured to zero so Net Work Time equals Gross Time and
/// the hours below read as the hours worked.
final class WorkdayManagerNotificationThresholdTests: XCTestCase {

    private var clock: ManualClock!
    private var store: InMemoryDailyLogStore!
    private var prompts: RecordingWorkdayPrompts!
    private var notifications: RecordingWorkdayNotifications!
    private var defaults: UserDefaults!
    private var manager: WorkdayManager!
    private var start: Date!
    private var idleSeconds: TimeInterval = 0

    override func setUp() {
        super.setUp()
        start = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 8))!
        clock = ManualClock(now: start)
        store = InMemoryDailyLogStore()
        idleSeconds = 0
        let suiteName = "notification-threshold-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        self.defaults = defaults
        addTeardownBlock { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(0, forKey: AppSettingsKey.breakAfter6hMinutes)
        defaults.set(0, forKey: AppSettingsKey.breakAfter9hMinutes)
        defaults.set(8.0, forKey: AppSettingsKey.normalNotificationHours)
        defaults.set(9.0, forKey: AppSettingsKey.criticalNotificationHours)
        defaults.set(10.0, forKey: AppSettingsKey.milestoneNotificationHours)
        defaults.set(true, forKey: AppSettingsKey.notificationsEnabled)
    }

    override func tearDown() {
        manager = nil
        clock = nil
        store = nil
        prompts = nil
        notifications = nil
        defaults = nil
        start = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// A fresh manager over the shared store, with fresh recorders.
    private func makeManager() -> WorkdayManager {
        prompts = RecordingWorkdayPrompts()
        notifications = RecordingWorkdayNotifications()
        let widgetSuiteName = "notification-threshold-widget-tests-\(UUID())"
        let widgetDefaults = UserDefaults(suiteName: widgetSuiteName)!
        addTeardownBlock { widgetDefaults.removePersistentDomain(forName: widgetSuiteName) }
        return WorkdayManager(
            defaults: defaults, clock: clock, store: store,
            idleDetector: IdleDetector(clock: clock, idleTime: { [weak self] in self?.idleSeconds ?? 0 }),
            prompts: prompts, notifications: notifications,
            widgetStore: SharedDefaults(defaults: widgetDefaults))
    }

    private func startWorkday() {
        manager = makeManager()
        manager.startNewDay()
    }

    /// Moves the clock to `hours` after the Workday started and ticks once.
    private func tick(atHours hours: Double) {
        clock.now = start.addingTimeInterval(hours * 3600)
        manager.tick()
    }

    /// The end-of-day prompt is presented asynchronously on the main queue.
    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }

    private func count(_ identifier: String) -> Int {
        notifications.thresholdIdentifiers.filter { $0 == identifier }.count
    }

    // MARK: - Milestone

    func testCrossingTheMilestoneNotifiesOnceAndPromptsToEndTheDay() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)

        tick(atHours: 10)
        drainMainQueue()

        XCTAssertEqual(count("milestone"), 1)
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

        tick(atHours: 10 + 1 / 3600)
        tick(atHours: 11)
        drainMainQueue()

        XCTAssertEqual(count("milestone"), 1)
        XCTAssertEqual(prompts.maxHoursPrompts.count, 1)
    }

    func testTheMilestoneIsRecordedSoAReloadedManagerDoesNotNotifyOrPromptAgain() {
        startWorkday()
        tick(atHours: 8)
        tick(atHours: 9)
        tick(atHours: 10)
        drainMainQueue()
        XCTAssertEqual(count("milestone"), 1)

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

        XCTAssertEqual(count("milestone"), 1)
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

        XCTAssertEqual(count("milestone"), 1)
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
        XCTAssertEqual(count("milestone"), 0)
        XCTAssertTrue(prompts.maxHoursPrompts.isEmpty)

        idleSeconds = 0
        tick(atHours: 10.5)
        drainMainQueue()

        XCTAssertEqual(count("milestone"), 1)
        XCTAssertEqual(prompts.maxHoursPrompts, [10.5])
    }
}

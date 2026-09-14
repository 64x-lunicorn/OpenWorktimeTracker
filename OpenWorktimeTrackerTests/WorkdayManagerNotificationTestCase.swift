import XCTest

@testable import OpenWorktimeTracker

/// Shared fixture for WorkdayManager's notification tests: a ManualClock, an
/// in-memory Daily Log store, recording prompt and notification adapters, an
/// isolated widget store, and fixed Notification Thresholds (8h normal, 9h
/// critical, 10h milestone).
///
/// Auto Break is configured to zero so Net Work Time equals Gross Time and the
/// hours in tests read directly as Net Work Time.
class WorkdayManagerNotificationTestCase: XCTestCase {

    var clock: ManualClock!
    var store: InMemoryDailyLogStore!
    var prompts: RecordingWorkdayPrompts!
    var notifications: RecordingWorkdayNotifications!
    var defaults: UserDefaults!
    var manager: WorkdayManager!
    var start: Date!
    /// Seconds since the last keyboard or mouse input, as the IdleDetector sees it.
    var idleSeconds: TimeInterval = 0

    override func setUp() {
        super.setUp()
        start = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 8))!
        clock = ManualClock(now: start)
        store = InMemoryDailyLogStore()
        idleSeconds = 0
        let suiteName = "notification-tests-\(UUID())"
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
        // Releasing the manager invalidates its Timer, and an end-of-day prompt
        // still queued finds no manager and does nothing.
        manager = nil
        clock = nil
        store = nil
        prompts = nil
        notifications = nil
        defaults = nil
        start = nil
        super.tearDown()
    }

    /// A fresh manager over the shared store, with fresh recorders.
    func makeManager() -> WorkdayManager {
        prompts = RecordingWorkdayPrompts()
        notifications = RecordingWorkdayNotifications()
        let widgetSuiteName = "notification-widget-tests-\(UUID())"
        let widgetDefaults = UserDefaults(suiteName: widgetSuiteName)!
        addTeardownBlock { widgetDefaults.removePersistentDomain(forName: widgetSuiteName) }
        return WorkdayManager(
            defaults: defaults, clock: clock, store: store,
            idleDetector: IdleDetector(clock: clock, idleTime: { [weak self] in self?.idleSeconds ?? 0 }),
            prompts: prompts, notifications: notifications,
            widgetStore: SharedDefaults(defaults: widgetDefaults))
    }

    func startWorkday() {
        manager = makeManager()
        manager.startNewDay()
    }

    /// Moves the clock to `hours` after the Workday started and ticks once.
    func tick(atHours hours: Double) {
        clock.now = start.addingTimeInterval(hours * 3600)
        manager.tick()
    }

    /// The end-of-day prompt is presented asynchronously on the main queue.
    func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }
}

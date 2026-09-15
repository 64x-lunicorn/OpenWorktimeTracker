import AppKit
import XCTest

@testable import OpenWorktimeTracker

final class WorkdayManagerLifecycleAndMutationTests: XCTestCase {

    private var clock: ManualClock!
    private var store: InMemoryDailyLogStore!
    private var manager: WorkdayManager!
    private var prompts: RecordingWorkdayPrompts!
    private var widgetStore: SharedDefaults!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        clock = ManualClock(now: date(day: 14, hour: 8))
        store = InMemoryDailyLogStore()
        prompts = RecordingWorkdayPrompts()
        let suiteName = "clock-store-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        self.defaults = defaults
        addTeardownBlock { defaults.removePersistentDomain(forName: suiteName) }
        let widgetSuiteName = "widget-manager-tests-\(UUID())"
        let widgetDefaults = UserDefaults(suiteName: widgetSuiteName)!
        addTeardownBlock { widgetDefaults.removePersistentDomain(forName: widgetSuiteName) }
        widgetStore = SharedDefaults(defaults: widgetDefaults)
        manager = WorkdayManager(
            defaults: defaults, clock: clock, store: store,
            idleDetector: IdleDetector(clock: clock, idleTime: { 0 }), prompts: prompts,
            widgetStore: widgetStore)
    }

    override func tearDown() {
        manager = nil
        store = nil
        clock = nil
        prompts = nil
        widgetStore = nil
        defaults = nil
        super.tearDown()
    }

    private func date(day: Int, hour: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    // MARK: - Ordered lifecycle through the same seam as macOS notifications

    func testSleepFlushesTheInjectedStoreBeforeReturning() {
        manager.bootstrap()
        clock.now = clock.now.addingTimeInterval(3600)

        manager.handleActivityEvent(.sleep)

        XCTAssertEqual(store.flushCallCount, 1)
        XCTAssertEqual(store.load(for: manager.currentEntry!.date)?.lastActivityTime, clock.now)
    }

    func testWorkspaceNotificationsReachOrderedLifecycleHandler() {
        manager.bootstrap()
        let start = clock.now
        let center = NSWorkspace.shared.notificationCenter
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        clock.now = clock.now.addingTimeInterval(600)

        center.post(name: NSWorkspace.didWakeNotification, object: nil)

        XCTAssertEqual(store.flushCallCount, 1)
        XCTAssertEqual(manager.pendingIdlePeriod?.idleStart, start)
        XCTAssertEqual(manager.pendingIdlePeriod?.idleEnd, clock.now)
        XCTAssertEqual(prompts.periods.count, 1)
    }

    func testWakeDuringManualPauseDoesNotCreateAnotherIdlePause() {
        manager.bootstrap()
        clock.now = clock.now.addingTimeInterval(3600)
        manager.pause()
        manager.handleActivityEvent(.sleep)
        manager.handleActivityEvent(.lock)
        clock.now = clock.now.addingTimeInterval(600)
        manager.handleActivityEvent(.wake)
        manager.handleActivityEvent(.unlock)

        XCTAssertEqual(manager.state, .paused)
        XCTAssertNil(manager.pendingIdlePeriod)
        XCTAssertTrue(prompts.periods.isEmpty)
        manager.resume()
        XCTAssertEqual(manager.pauseTime, 600)
        XCTAssertEqual(manager.netTime, 3600)
    }

    // MARK: - Complete Daily Log mutations

    func testFailedSavePreservesStoredAndPublishedStateAndCanBeRetried() {
        manager.startNewDay()
        let original = manager.currentEntry!
        let revision = manager.logRevision
        let dismissCount = prompts.dismissCount
        var edited = original
        edited.startTime = original.startTime.addingTimeInterval(-3600)
        edited.note = "Keep this draft"
        store.saveSucceeds = false

        XCTAssertNil(manager.saveEdits(edited, original: original))

        XCTAssertEqual(manager.logMutationError, .saveFailed)
        XCTAssertEqual(manager.currentEntry?.startTime, original.startTime)
        XCTAssertEqual(store.load(for: original.date)?.note, original.note)
        XCTAssertEqual(manager.logRevision, revision)
        XCTAssertEqual(prompts.dismissCount, dismissCount)
        XCTAssertEqual(manager.grossTime, 0)

        store.saveSucceeds = true
        XCTAssertNotNil(manager.saveEdits(edited, original: original))
        XCTAssertNil(manager.logMutationError)
        XCTAssertEqual(manager.currentEntry?.note, edited.note)
        XCTAssertEqual(store.load(for: original.date)?.note, edited.note)
        XCTAssertEqual(manager.grossTime, 3600)
        XCTAssertEqual(manager.logRevision, revision + 1)
    }

    func testFailedDeletePreservesTrackingPromptAndRevision() {
        manager.bootstrap()
        let original = manager.currentEntry!
        manager.handleActivityEvent(.lock)
        clock.now = clock.now.addingTimeInterval(600)
        manager.handleActivityEvent(.unlock)
        let pendingID = manager.pendingIdlePeriod?.id
        let revision = manager.logRevision
        let dismissCount = prompts.dismissCount
        store.deleteSucceeds = false

        XCTAssertFalse(manager.deleteLog(original))

        XCTAssertEqual(manager.logMutationError, .deleteFailed)
        XCTAssertEqual(manager.state, .running)
        XCTAssertEqual(manager.currentEntry?.id, original.id)
        XCTAssertNotNil(store.load(for: original.date))
        XCTAssertEqual(manager.logRevision, revision)
        XCTAssertEqual(manager.pendingIdlePeriod?.id, pendingID)
        XCTAssertEqual(prompts.dismissCount, dismissCount)

        store.deleteSucceeds = true
        XCTAssertTrue(manager.deleteLog(original))
        XCTAssertNil(manager.logMutationError)
        XCTAssertEqual(manager.state, .notStarted)
        XCTAssertNil(manager.pendingIdlePeriod)
        XCTAssertEqual(prompts.dismissCount, dismissCount + 1)
        XCTAssertEqual(manager.logRevision, revision + 1)
        manager.tick()
        XCTAssertNil(store.load(for: original.date))
    }

    func testStaleDeleteDoesNotRemoveReplacementRecord() {
        manager.startNewDay()
        let original = manager.currentEntry!
        let replacement = TimeEntry(date: original.date, startTime: clock.now)
        store.save(replacement)
        let revision = manager.logRevision

        XCTAssertFalse(manager.deleteLog(original))

        XCTAssertEqual(manager.logMutationError, .missingEntry)
        XCTAssertEqual(store.load(for: original.date)?.id, replacement.id)
        XCTAssertEqual(manager.logRevision, revision)
    }

    func testEditorValidationAndSaveAcceptZeroDurationEndedDay() {
        manager.startNewDay()
        manager.endDay()
        let original = manager.currentEntry!
        var edited = original
        edited.note = "A zero-duration day is valid"

        XCTAssertTrue(manager.hasValidLogTimes(edited))
        XCTAssertNotNil(manager.saveEdits(edited, original: original))
        XCTAssertEqual(manager.grossTime, 0)
    }

    func testEditorValidationAndSaveRejectFutureStartUsingInjectedClock() {
        manager.startNewDay()
        let original = manager.currentEntry!
        var edited = original
        edited.startTime = clock.now.addingTimeInterval(60)
        let revision = manager.logRevision

        XCTAssertFalse(manager.hasValidLogTimes(edited))
        XCTAssertNil(manager.saveEdits(edited, original: original))
        XCTAssertEqual(manager.logMutationError, .invalidTimes)
        XCTAssertEqual(manager.logRevision, revision)
        XCTAssertEqual(store.load(for: original.date)?.startTime, original.startTime)
    }

    func testInvalidPauseCannotBeSavedThroughMutationInterface() {
        manager.startNewDay()
        let original = manager.currentEntry!
        for pause in [TimeInterval.nan, .infinity, -1] {
            var edited = original
            edited.manualPauseSeconds = pause

            XCTAssertFalse(manager.hasValidLogTimes(edited))
            XCTAssertNil(manager.saveEdits(edited, original: original))
            XCTAssertEqual(manager.logMutationError, .invalidTimes)
            XCTAssertEqual(store.load(for: original.date)?.manualPauseSeconds, 0)
        }
    }

    func testLogEditorQueriesTheInjectedStore() {
        let previous = TimeEntry(date: "2026-09-13", startTime: date(day: 13, hour: 8))
        store.save(previous)
        manager.startNewDay()

        XCTAssertEqual(manager.loadDailyLogs().map(\.date), ["2026-09-14", "2026-09-13"])
    }

    func testWakeBeforeUnlockWaitsForUnlockAndPresentsOnce() {
        assertOvernightEvents(firstReturn: .wake, lastReturn: .unlock)
    }

    func testUnlockBeforeWakeWaitsForWakeAndPresentsOnce() {
        assertOvernightEvents(firstReturn: .unlock, lastReturn: .wake)
    }

    private func assertOvernightEvents(
        firstReturn: IdleDetector.ActivityEvent, lastReturn: IdleDetector.ActivityEvent
    ) {
        manager.bootstrap()
        let previous = manager.currentEntry!
        clock.now = date(day: 14, hour: 17)
        manager.handleActivityEvent(.lock)
        manager.handleActivityEvent(.sleep)
        manager.handleActivityEvent(.sleep)
        clock.now = date(day: 15, hour: 8)

        manager.handleActivityEvent(firstReturn)
        manager.tick()
        XCTAssertNil(manager.pendingIdlePeriod)
        XCTAssertTrue(prompts.periods.isEmpty)
        XCTAssertEqual(manager.currentEntry?.id, previous.id)

        manager.handleActivityEvent(lastReturn)
        manager.handleActivityEvent(lastReturn)
        manager.handleActivityEvent(firstReturn)
        manager.tick()

        XCTAssertEqual(prompts.periods.count, 1)
        XCTAssertEqual(manager.pendingIdlePeriod?.idleStart, date(day: 14, hour: 17))
        XCTAssertEqual(manager.pendingIdlePeriod?.idleEnd, clock.now)
        XCTAssertEqual(manager.currentEntry?.id, previous.id)
        XCTAssertEqual(store.load(for: previous.date)?.status, .running)

        let dismissCount = prompts.dismissCount
        manager.handleNewDayFromIdle(endYesterdayAt: date(day: 14, hour: 17))
        XCTAssertEqual(prompts.dismissCount, dismissCount + 1)
        XCTAssertNil(manager.pendingIdlePeriod)
        XCTAssertEqual(manager.currentEntry?.date, "2026-09-15")
        XCTAssertEqual(store.load(for: previous.date)?.endTime, date(day: 14, hour: 17))
    }

    func testSleepWithoutScreenLockStillProducesIdleDecision() {
        manager.bootstrap()
        let start = clock.now
        manager.handleActivityEvent(.sleep)
        clock.now = clock.now.addingTimeInterval(600)

        manager.handleActivityEvent(.wake)

        XCTAssertEqual(prompts.periods.count, 1)
        XCTAssertEqual(manager.pendingIdlePeriod?.idleStart, start)
        XCTAssertEqual(manager.pendingIdlePeriod?.idleEnd, clock.now)
        XCTAssertFalse(manager.idleDetector.isIdle)
    }

    func testWakeBelowIdleThresholdImmediatelyKeepsCurrentWorkday() {
        manager.bootstrap()
        let id = manager.currentEntry?.id
        manager.handleActivityEvent(.lock)
        clock.now = clock.now.addingTimeInterval(60)
        manager.handleActivityEvent(.unlock)

        XCTAssertNil(manager.pendingIdlePeriod)
        XCTAssertTrue(prompts.periods.isEmpty)
        XCTAssertEqual(manager.currentEntry?.id, id)
        XCTAssertEqual(manager.grossTime, 60)
    }

    func testClosingIdlePromptAllowsNextPeriodWithoutDuplicateCleanup() {
        manager.bootstrap()
        manager.handleActivityEvent(.lock)
        clock.now = clock.now.addingTimeInterval(600)
        manager.handleActivityEvent(.unlock)
        let dismissCount = prompts.dismissCount

        manager.dismissIdlePeriod()

        XCTAssertEqual(prompts.dismissCount, dismissCount + 1)
        XCTAssertNil(manager.pendingIdlePeriod)
        manager.handleActivityEvent(.lock)
        clock.now = clock.now.addingTimeInterval(600)
        manager.handleActivityEvent(.unlock)
        XCTAssertEqual(prompts.periods.count, 2)
    }

    func testEndedDayDoesNotRestartWhileScreenRemainsLocked() {
        manager.bootstrap()
        manager.endDay()
        manager.handleActivityEvent(.lock)
        manager.handleActivityEvent(.sleep)
        clock.now = date(day: 15, hour: 8)

        manager.handleActivityEvent(.wake)
        manager.tick()

        XCTAssertEqual(manager.state, .ended)
        manager.handleActivityEvent(.unlock)
        XCTAssertEqual(manager.state, .running)
        XCTAssertEqual(manager.currentEntry?.startTime, clock.now)
        XCTAssertTrue(prompts.periods.isEmpty)
    }
}

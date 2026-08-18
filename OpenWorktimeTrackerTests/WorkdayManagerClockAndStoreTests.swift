import XCTest

@testable import OpenWorktimeTracker

/// Tests that exercise WorkdayManager's Clock/DailyLogStore seams:
/// time-dependent behaviour asserted against an exact instant instead of a
/// tolerance, and no filesystem I/O for the Daily Log.
final class WorkdayManagerClockAndStoreTests: XCTestCase {

    private var clock: ManualClock!
    private var store: InMemoryDailyLogStore!
    private var manager: WorkdayManager!

    override func setUp() {
        super.setUp()
        clock = ManualClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        store = InMemoryDailyLogStore()
        manager = WorkdayManager(clock: clock, store: store)
    }

    override func tearDown() {
        manager = nil
        store = nil
        clock = nil
        super.tearDown()
    }

    // MARK: - Exact timestamps

    func testStartNewDayUsesTheInjectedClockExactly() {
        manager.startNewDay()
        XCTAssertEqual(manager.currentEntry?.startTime, clock.now)
    }

    func testPauseUsesTheInjectedClockExactly() {
        manager.startNewDay()
        clock.now = clock.now.addingTimeInterval(3600)

        manager.pause()

        XCTAssertEqual(manager.currentEntry?.pauseStartedAt, clock.now)
    }

    func testResumeAccumulatesExactlyTheInjectedClockDelta() {
        manager.startNewDay()
        manager.pause()
        clock.now = clock.now.addingTimeInterval(900)

        manager.resume()

        XCTAssertEqual(manager.currentEntry?.manualPauseSeconds ?? 0, 900)
    }

    func testEndDayUsesTheInjectedClockExactly() {
        manager.startNewDay()
        clock.now = clock.now.addingTimeInterval(7200)

        manager.endDay()

        XCTAssertEqual(manager.currentEntry?.endTime, clock.now)
    }

    func testUpdateStartTimeRejectsAnInstantAfterTheInjectedNow() {
        manager.startNewDay()
        let future = clock.now.addingTimeInterval(60)

        manager.updateStartTime(future)

        XCTAssertNotEqual(manager.currentEntry?.startTime, future)
    }

    // MARK: - Deterministic published values

    func testNetTimeIsComputedAgainstTheInjectedClock() {
        manager.startNewDay()
        // 7h elapsed, past the 6h Auto Break threshold with default rules
        // (30min owed): 6h30m net.
        clock.now = clock.now.addingTimeInterval(7 * 3600)
        manager.updateStartTime(manager.currentEntry!.startTime)  // triggers a recompute

        XCTAssertEqual(manager.netTime, 6 * 3600 + 30 * 60, accuracy: 0.5)
        XCTAssertEqual(manager.grossTime, 7 * 3600, accuracy: 0.5)
    }

    // MARK: - No filesystem I/O

    func testStartNewDaySavesToTheInjectedStoreNotRealDisk() {
        manager.startNewDay()

        XCTAssertNotNil(store.load(for: manager.currentEntry!.date))
    }

    func testBootstrapSyncsThroughTheInjectedStore() {
        manager.bootstrap()

        XCTAssertEqual(store.syncWithCloudCallCount, 1)
    }
}

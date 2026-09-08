import XCTest

@testable import OpenWorktimeTracker

/// Coverage for the four Idle Decision handlers, previously untested. Written
/// against the consolidated `finish(at:)` end path — the state each handler
/// leaves behind, not the effects, per the interface WorkdayTests already
/// established as the test surface.
final class WorkdayManagerIdleHandlingTests: XCTestCase {

    private var manager: WorkdayManager!
    private var clock: ManualClock!

    override func setUp() {
        super.setUp()
        clock = ManualClock(now: Calendar.current.date(
            from: DateComponents(year: 2026, month: 9, day: 14, hour: 8))!)
        manager = WorkdayManager(clock: clock, store: InMemoryDailyLogStore())
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    private func stagePendingIdlePeriod(idleStart: Date, idleEnd: Date, spansMidnight: Bool = false) {
        manager.pendingIdlePeriod = IdlePeriod(
            idleStart: idleStart,
            idleEnd: idleEnd,
            spansMidnight: spansMidnight
        )
    }

    func testHandleIdleDecisionAndEndDayEndsAtIdleStart() {
        manager.startNewDay()
        clock.now = clock.now.addingTimeInterval(3600)
        let idleStart = clock.now
        clock.now = clock.now.addingTimeInterval(1800)
        stagePendingIdlePeriod(idleStart: idleStart, idleEnd: clock.now)

        manager.handleIdleDecisionAndEndDay()

        XCTAssertEqual(manager.state, .ended)
        XCTAssertEqual(manager.currentEntry?.status, .ended)
        XCTAssertEqual(manager.currentEntry?.endTime, idleStart)
        XCTAssertEqual(manager.currentEntry?.idleDecisions.last?.decision, .pause)
        XCTAssertNil(manager.pendingIdlePeriod)
    }

    func testHandleIdleDecisionAndRestartPreservesEntry() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id
        clock.now = clock.now.addingTimeInterval(3600)
        stagePendingIdlePeriod(idleStart: clock.now.addingTimeInterval(-1800), idleEnd: clock.now)

        manager.handleIdleDecisionAndRestart()

        XCTAssertEqual(manager.state, .running)
        XCTAssertEqual(manager.currentEntry?.id, originalID)
        XCTAssertNil(manager.pendingIdlePeriod)
    }

    func testHandleNewDayFromIdleEndsYesterdayAndStartsToday() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id
        let idleStart = clock.now.addingTimeInterval(8 * 3600)
        clock.now = clock.now.addingTimeInterval(24 * 3600)
        stagePendingIdlePeriod(idleStart: idleStart, idleEnd: clock.now, spansMidnight: true)

        manager.handleNewDayFromIdle(endYesterdayAt: idleStart)

        XCTAssertEqual(manager.state, .running)
        XCTAssertNotEqual(manager.currentEntry?.id, originalID)
        XCTAssertNil(manager.pendingIdlePeriod)
    }

    func testHandleIdleDecisionAndEndDayWithNoPendingPromptIsNoOp() {
        manager.startNewDay()
        manager.handleIdleDecisionAndEndDay()

        XCTAssertEqual(manager.state, .running)
    }

    func testHandleIdleDecisionAndRestartWithNoPendingPromptIsNoOp() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id

        manager.handleIdleDecisionAndRestart()

        XCTAssertEqual(manager.currentEntry?.id, originalID)
        XCTAssertEqual(manager.state, .running)
    }

    func testHandleNewDayFromIdleWithNoPendingPromptIsNoOp() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id

        manager.handleNewDayFromIdle(endYesterdayAt: Date())

        XCTAssertEqual(manager.currentEntry?.id, originalID)
        XCTAssertEqual(manager.state, .running)
    }
}

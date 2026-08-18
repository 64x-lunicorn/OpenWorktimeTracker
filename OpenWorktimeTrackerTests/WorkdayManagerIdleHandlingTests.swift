import XCTest

@testable import OpenWorktimeTracker

/// Coverage for the four Idle Decision handlers, previously untested. Written
/// against the consolidated `finish(at:)` end path — the state each handler
/// leaves behind, not the effects, per the interface WorkdayTests already
/// established as the test surface.
final class WorkdayManagerIdleHandlingTests: XCTestCase {

    private var manager: WorkdayManager!

    override func setUp() {
        super.setUp()
        manager = WorkdayManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    private func pendingPrompt(idleStart: Date, idleEnd: Date, spansMidnight: Bool = false) {
        manager.idleDetector.pendingPrompt = IdlePromptInfo(
            idleStart: idleStart,
            idleEnd: idleEnd,
            duration: idleEnd.timeIntervalSince(idleStart),
            spansMidnight: spansMidnight
        )
    }

    func testHandleIdleDecisionAndEndDayEndsAtIdleStart() {
        manager.startNewDay()
        let idleStart = Date().addingTimeInterval(-1800)
        pendingPrompt(idleStart: idleStart, idleEnd: Date())

        manager.handleIdleDecisionAndEndDay()

        XCTAssertEqual(manager.state, .ended)
        XCTAssertEqual(manager.currentEntry?.status, .ended)
        XCTAssertEqual(manager.currentEntry?.endTime, idleStart)
        XCTAssertEqual(manager.currentEntry?.idleDecisions.last?.decision, .pause)
        XCTAssertNil(manager.idleDetector.pendingPrompt)
    }

    func testHandleIdleDecisionAndRestartStartsANewEntry() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id
        pendingPrompt(idleStart: Date().addingTimeInterval(-1800), idleEnd: Date())

        manager.handleIdleDecisionAndRestart()

        XCTAssertEqual(manager.state, .running)
        XCTAssertNotEqual(manager.currentEntry?.id, originalID)
        XCTAssertNil(manager.idleDetector.pendingPrompt)
    }

    func testHandleNewDayFromIdleEndsYesterdayAndStartsToday() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id
        let idleStart = Date().addingTimeInterval(-3600)
        pendingPrompt(idleStart: idleStart, idleEnd: Date(), spansMidnight: true)

        manager.handleNewDayFromIdle(endYesterdayAt: idleStart)

        XCTAssertEqual(manager.state, .running)
        XCTAssertNotEqual(manager.currentEntry?.id, originalID)
        XCTAssertNil(manager.idleDetector.pendingPrompt)
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

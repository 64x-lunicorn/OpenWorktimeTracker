import XCTest

@testable import OpenWorktimeTracker

/// Extended tests for WorkdayManager covering idle handling, state transitions, and bug fixes.
final class WorkdayManagerExtendedTests: XCTestCase {

    private var manager: WorkdayManager!

    override func setUp() {
        super.setUp()
        manager = WorkdayManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Pause/Resume Idempotency

    func testMultiplePausesDoNotAccumulateState() {
        manager.startNewDay()
        manager.pause()
        let firstPauseStart = manager.currentEntry?.pauseStartedAt

        // Second pause should be no-op (already paused)
        manager.pause()
        XCTAssertEqual(manager.currentEntry?.pauseStartedAt, firstPauseStart)
        XCTAssertEqual(manager.state, .paused)
    }

    func testMultipleResumesDoNotAccumulate() {
        manager.startNewDay()
        manager.pause()
        manager.resume()

        let pauseAfterResume = manager.currentEntry?.manualPauseSeconds ?? 0

        // Second resume should be no-op (already running)
        manager.resume()
        XCTAssertEqual(manager.currentEntry?.manualPauseSeconds ?? 0, pauseAfterResume)
        XCTAssertEqual(manager.state, .running)
    }

    // MARK: - End Day Clears Pause

    func testEndDayFromPausedFinalizesCurrentPause() {
        manager.startNewDay()
        manager.pause()

        // Verify pause is active
        XCTAssertNotNil(manager.currentEntry?.pauseStartedAt)

        manager.endDay()

        // Pause should be finalized
        XCTAssertNil(manager.currentEntry?.pauseStartedAt)
        XCTAssertGreaterThanOrEqual(manager.currentEntry?.manualPauseSeconds ?? 0, 0)
    }

    // MARK: - Update Start/End Time Validations

    func testUpdateStartTimeWithNoEntryIsNoOp() {
        manager.updateStartTime(Date())
        XCTAssertNil(manager.currentEntry)
    }

    func testUpdateEndTimeWithNoEntryIsNoOp() {
        manager.updateEndTime(Date())
        XCTAssertNil(manager.currentEntry)
    }

    func testUpdateEndTimeWhileRunningIsRejected() {
        manager.startNewDay()
        XCTAssertEqual(manager.state, .running)

        let futureEnd = Date().addingTimeInterval(3600)
        manager.updateEndTime(futureEnd)

        // Should still be nil since state is .running, not .ended
        XCTAssertNil(manager.currentEntry?.endTime)
    }

    func testUpdateStartTimeToValidEarlierTime() {
        manager.startNewDay()
        let originalStart = manager.currentEntry?.startTime
        let earlierStart = Date().addingTimeInterval(-7200)  // 2h earlier

        manager.updateStartTime(earlierStart)

        XCTAssertEqual(manager.currentEntry?.startTime, earlierStart)
        XCTAssertNotEqual(manager.currentEntry?.startTime, originalStart)
    }

    // MARK: - Restart Day

    func testRestartDayFromEndedState() {
        manager.startNewDay()
        manager.endDay()
        XCTAssertEqual(manager.state, .ended)

        let endedEntryID = manager.currentEntry?.id
        manager.restartDay()

        XCTAssertEqual(manager.state, .running)
        XCTAssertNotEqual(manager.currentEntry?.id, endedEntryID)
        XCTAssertNil(manager.currentEntry?.endTime)
    }

    // MARK: - Note Update

    func testUpdateNotePreservesOtherFields() {
        manager.startNewDay()
        let startTime = manager.currentEntry?.startTime
        let id = manager.currentEntry?.id

        manager.updateNote("Important meeting notes")

        XCTAssertEqual(manager.currentEntry?.note, "Important meeting notes")
        XCTAssertEqual(manager.currentEntry?.startTime, startTime)
        XCTAssertEqual(manager.currentEntry?.id, id)
    }

    func testUpdateNoteMultipleTimes() {
        manager.startNewDay()
        manager.updateNote("First note")
        manager.updateNote("Second note")
        manager.updateNote("Final note")

        XCTAssertEqual(manager.currentEntry?.note, "Final note")
    }

    // MARK: - Menu Bar Title

    func testMenuBarTitleNotStarted() {
        XCTAssertEqual(manager.menuBarTitle, "--:--")
    }

    func testMenuBarTitleRunning() {
        manager.startNewDay()
        XCTAssertFalse(manager.menuBarTitle.isEmpty)
        // Should show a time format, not "--:--"
        XCTAssertNotEqual(manager.menuBarTitle, "--:--")
    }

    func testMenuBarTitlePaused() {
        manager.startNewDay()
        manager.pause()
        XCTAssertTrue(manager.menuBarTitle.hasPrefix("||"))
    }

    func testMenuBarTitleEnded() {
        manager.startNewDay()
        manager.endDay()
        let title = manager.menuBarTitle
        // Should show time without prefix
        XCTAssertFalse(title.hasPrefix("||"))
        XCTAssertNotEqual(title, "--:--")
    }

    // MARK: - Estimated End Time

    func testEstimatedEndTimeWhenPaused() {
        manager.startNewDay()
        manager.pause()
        // Should be nil when paused (only works when running)
        XCTAssertNil(manager.estimatedEndTime)
    }

    // MARK: - Idle Decision Handling

    func testHandleIdleDecisionWithNoPendingPromptIsNoOp() {
        manager.startNewDay()

        let idleCountBefore = manager.currentEntry?.idleDecisions.count ?? 0
        manager.handleIdleDecision(.work)

        // Should not add decision since no pending prompt
        XCTAssertEqual(manager.currentEntry?.idleDecisions.count ?? 0, idleCountBefore)
    }

    func testHandleIdleDecisionWithNoEntryIsNoOp() {
        // No entry, no prompt
        manager.handleIdleDecision(.pause)
        XCTAssertNil(manager.currentEntry)
    }

    // MARK: - State Consistency

    func testEntryStatusMatchesManagerState() {
        manager.startNewDay()
        XCTAssertEqual(manager.currentEntry?.status, .running)
        XCTAssertEqual(manager.state, .running)

        manager.pause()
        XCTAssertEqual(manager.currentEntry?.status, .paused)
        XCTAssertEqual(manager.state, .paused)

        manager.resume()
        XCTAssertEqual(manager.currentEntry?.status, .running)
        XCTAssertEqual(manager.state, .running)

        manager.endDay()
        XCTAssertEqual(manager.currentEntry?.status, .ended)
        XCTAssertEqual(manager.state, .ended)
    }

    // MARK: - Computed Values

    func testComputedValuesAfterStartAreReasonable() {
        manager.startNewDay()

        // Immediately after start, all values should be near zero
        XCTAssertGreaterThanOrEqual(manager.grossTime, 0)
        XCTAssertGreaterThanOrEqual(manager.netTime, 0)
        XCTAssertEqual(manager.manualPause, 0, accuracy: 1)
        XCTAssertEqual(manager.autoBreak, 0)
    }

    func testComputedValuesAfterEnd() {
        manager.startNewDay()
        manager.endDay()

        XCTAssertGreaterThanOrEqual(manager.grossTime, 0)
        XCTAssertGreaterThanOrEqual(manager.netTime, 0)
    }
}

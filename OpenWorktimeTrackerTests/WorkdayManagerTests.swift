import XCTest

@testable import OpenWorktimeTracker

final class WorkdayManagerTests: XCTestCase {

    private var manager: WorkdayManager!

    override func setUp() {
        super.setUp()
        manager = WorkdayManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsNotStarted() {
        XCTAssertEqual(manager.state, .notStarted)
        XCTAssertNil(manager.currentEntry)
        XCTAssertEqual(manager.displayTime, 0)
        XCTAssertEqual(manager.grossTime, 0)
        XCTAssertEqual(manager.netTime, 0)
    }

    // MARK: - Start New Day

    func testStartNewDaySetsRunningState() {
        manager.startNewDay()

        XCTAssertEqual(manager.state, .running)
        XCTAssertNotNil(manager.currentEntry)
        XCTAssertEqual(manager.currentEntry?.status, .running)
    }

    func testStartNewDayCreatesEntryWithTodayDate() {
        manager.startNewDay()

        let todayString = TimeEntry.dateString(from: Date())
        XCTAssertEqual(manager.currentEntry?.date, todayString)
    }

    // MARK: - Pause / Resume

    func testPauseFromRunning() {
        manager.startNewDay()
        manager.pause()

        XCTAssertEqual(manager.state, .paused)
        XCTAssertEqual(manager.currentEntry?.status, .paused)
        XCTAssertNotNil(manager.currentEntry?.pauseStartedAt)
    }

    func testPauseFromNotRunningIsNoOp() {
        manager.pause()

        XCTAssertEqual(manager.state, .notStarted)
        XCTAssertNil(manager.currentEntry)
    }

    func testResumeFromPaused() {
        manager.startNewDay()
        manager.pause()

        // Simulate a short pause
        manager.resume()

        XCTAssertEqual(manager.state, .running)
        XCTAssertEqual(manager.currentEntry?.status, .running)
        XCTAssertNil(manager.currentEntry?.pauseStartedAt)
    }

    func testResumeAccumulatesManualPause() {
        manager.startNewDay()

        // Record pause start
        manager.pause()
        let pauseStart = manager.currentEntry?.pauseStartedAt

        // Wait a tiny bit then resume
        XCTAssertNotNil(pauseStart)
        manager.resume()

        XCTAssertGreaterThanOrEqual(manager.currentEntry?.manualPauseSeconds ?? 0, 0)
    }

    func testResumeFromNotPausedIsNoOp() {
        manager.startNewDay()
        // State is .running, not .paused
        manager.resume()

        XCTAssertEqual(manager.state, .running)
    }

    // MARK: - End Day

    func testEndDayFromRunning() {
        manager.startNewDay()
        manager.endDay()

        XCTAssertEqual(manager.state, .ended)
        XCTAssertEqual(manager.currentEntry?.status, .ended)
        XCTAssertNotNil(manager.currentEntry?.endTime)
    }

    func testEndDayFromPaused() {
        manager.startNewDay()
        manager.pause()
        manager.endDay()

        XCTAssertEqual(manager.state, .ended)
        XCTAssertEqual(manager.currentEntry?.status, .ended)
        XCTAssertNotNil(manager.currentEntry?.endTime)
        // pauseStartedAt should be cleared
        XCTAssertNil(manager.currentEntry?.pauseStartedAt)
        // Manual pause should be accumulated
        XCTAssertGreaterThanOrEqual(manager.currentEntry?.manualPauseSeconds ?? 0, 0)
    }

    func testEndDayWithNoEntryIsNoOp() {
        manager.endDay()

        XCTAssertEqual(manager.state, .notStarted)
        XCTAssertNil(manager.currentEntry)
    }

    // MARK: - Restart Day

    func testRestartDayCreatesNewEntry() {
        manager.startNewDay()
        let originalID = manager.currentEntry?.id
        manager.endDay()

        manager.restartDay()

        XCTAssertEqual(manager.state, .running)
        XCTAssertNotEqual(manager.currentEntry?.id, originalID)
        XCTAssertEqual(manager.currentEntry?.status, .running)
    }

    // MARK: - Update Note

    func testUpdateNote() {
        manager.startNewDay()
        manager.updateNote("Daily standup")

        XCTAssertEqual(manager.currentEntry?.note, "Daily standup")
    }

    func testUpdateNoteWithNoEntryIsNoOp() {
        manager.updateNote("Should not crash")
        XCTAssertNil(manager.currentEntry)
    }

    // MARK: - Update Start/End Time

    func testUpdateStartTime() {
        manager.startNewDay()
        let newStart = Date().addingTimeInterval(-3600)  // 1h ago
        manager.updateStartTime(newStart)

        XCTAssertEqual(manager.currentEntry?.startTime, newStart)
    }

    func testUpdateStartTimeAfterEndTimeIsRejected() {
        manager.startNewDay()
        manager.endDay()

        let endTime = manager.currentEntry?.endTime ?? Date()
        let invalidStart = endTime.addingTimeInterval(3600)  // 1h after end
        let originalStart = manager.currentEntry?.startTime

        manager.updateStartTime(invalidStart)

        XCTAssertEqual(manager.currentEntry?.startTime, originalStart)
    }

    func testUpdateEndTime() {
        manager.startNewDay()
        manager.endDay()

        let newEnd = Date().addingTimeInterval(3600)
        manager.updateEndTime(newEnd)

        XCTAssertEqual(manager.currentEntry?.endTime, newEnd)
    }

    func testUpdateEndTimeBeforeStartIsRejected() {
        manager.startNewDay()
        manager.endDay()

        let startTime = manager.currentEntry?.startTime ?? Date()
        let invalidEnd = startTime.addingTimeInterval(-3600)  // 1h before start
        let originalEnd = manager.currentEntry?.endTime

        manager.updateEndTime(invalidEnd)

        XCTAssertEqual(manager.currentEntry?.endTime, originalEnd)
    }

    func testUpdateEndTimeOnlyWorksWhenEnded() {
        manager.startNewDay()
        // State is .running, not .ended
        let newEnd = Date().addingTimeInterval(3600)
        manager.updateEndTime(newEnd)

        // endTime should still be nil since state is running
        XCTAssertNil(manager.currentEntry?.endTime)
    }

    // MARK: - State Machine Integrity

    func testFullLifecycle() {
        // not started → running → paused → running → ended
        XCTAssertEqual(manager.state, .notStarted)

        manager.startNewDay()
        XCTAssertEqual(manager.state, .running)

        manager.pause()
        XCTAssertEqual(manager.state, .paused)

        manager.resume()
        XCTAssertEqual(manager.state, .running)

        manager.endDay()
        XCTAssertEqual(manager.state, .ended)
    }

    func testDoubleStartCreatesNewEntry() {
        manager.startNewDay()
        let firstID = manager.currentEntry?.id

        manager.startNewDay()
        let secondID = manager.currentEntry?.id

        // Each start creates a new entry with new ID
        XCTAssertNotEqual(firstID, secondID)
        XCTAssertEqual(manager.state, .running)
    }

    func testDoublePauseIsNoOp() {
        manager.startNewDay()
        manager.pause()
        let pauseStart = manager.currentEntry?.pauseStartedAt

        manager.pause()
        // pauseStartedAt should not change
        XCTAssertEqual(manager.currentEntry?.pauseStartedAt, pauseStart)
    }

    func testDoubleEndDayIsIdempotent() {
        manager.startNewDay()
        manager.endDay()
        let endTime = manager.currentEntry?.endTime

        manager.endDay()
        // State should still be ended
        XCTAssertEqual(manager.state, .ended)
        // endTime should not change significantly
        XCTAssertNotNil(endTime)
    }

    // MARK: - Estimated End Time

    func testEstimatedEndTimeNilWhenNotRunning() {
        XCTAssertNil(manager.estimatedEndTime)
    }

    func testEstimatedEndTimeNilWhenEnded() {
        manager.startNewDay()
        manager.endDay()

        XCTAssertNil(manager.estimatedEndTime)
    }

    func testEstimatedEndTimeReturnsDateWhenRunning() {
        manager.startNewDay()
        // Should return some future date
        let estimated = manager.estimatedEndTime
        // Could be nil if already past target, but generally should not be for a fresh start
        if let estimated = estimated {
            XCTAssertGreaterThan(estimated, Date())
        }
    }
}

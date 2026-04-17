import XCTest

@testable import OpenWorktimeTracker

final class TimeEntryTests: XCTestCase {

    func testDateStringFormat() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: "2026-04-15")!

        XCTAssertEqual(TimeEntry.dateString(from: date), "2026-04-15")
    }

    func testGrossTimeCalculation() {
        let start = Date()
        let entry = TimeEntry(startTime: start, endTime: start.addingTimeInterval(3600))
        XCTAssertEqual(entry.grossTime, 3600, accuracy: 1)
    }

    func testTotalIdlePauseOnlyCountsPauses() {
        var entry = TimeEntry(startTime: Date())
        entry.idleDecisions = [
            IdleDecision(
                idleStart: Date().addingTimeInterval(-1200),
                idleEnd: Date().addingTimeInterval(-600),
                decision: .pause  // 10 min
            ),
            IdleDecision(
                idleStart: Date().addingTimeInterval(-600),
                idleEnd: Date(),
                decision: .work  // Should NOT be counted
            ),
        ]

        XCTAssertEqual(entry.totalIdlePause, 600, accuracy: 1)
    }

    func testWorkTimeBeforeAutoBreak() {
        let start = Date()
        var entry = TimeEntry(startTime: start, endTime: start.addingTimeInterval(8 * 3600))
        entry.manualPauseSeconds = 900  // 15 min

        let expected = 8 * 3600.0 - 900.0
        XCTAssertEqual(entry.workTimeBeforeAutoBreak, expected, accuracy: 1)
    }

    // MARK: - Edge Cases

    func testGrossTimeNeverNegative() {
        // End before start — grossTime should be 0 via max(0, ...)
        let start = Date()
        let entry = TimeEntry(startTime: start, endTime: start.addingTimeInterval(-100))
        XCTAssertEqual(entry.grossTime, 0)
    }

    func testWorkTimeBeforeAutoBreakNeverNegative() {
        let start = Date()
        var entry = TimeEntry(startTime: start, endTime: start.addingTimeInterval(1800))
        entry.manualPauseSeconds = 3600  // More pause than gross time
        XCTAssertGreaterThanOrEqual(entry.workTimeBeforeAutoBreak, 0)
    }

    func testTotalPauseCombinesManualAndIdle() {
        let start = Date()
        var entry = TimeEntry(startTime: start, endTime: start.addingTimeInterval(8 * 3600))
        entry.manualPauseSeconds = 600
        entry.idleDecisions = [
            IdleDecision(
                idleStart: start.addingTimeInterval(3600),
                idleEnd: start.addingTimeInterval(4200),
                decision: .pause  // 10 min
            )
        ]

        XCTAssertEqual(entry.totalPause, 1200, accuracy: 1)  // 600 manual + 600 idle
    }

    func testNoIdleDecisionsMeansZeroIdlePause() {
        let entry = TimeEntry(startTime: Date())
        XCTAssertEqual(entry.totalIdlePause, 0)
    }

    func testIdleDecisionWorkIsNotCounted() {
        var entry = TimeEntry(startTime: Date())
        entry.idleDecisions = [
            IdleDecision(
                idleStart: Date().addingTimeInterval(-600),
                idleEnd: Date(),
                decision: .work
            )
        ]
        XCTAssertEqual(entry.totalIdlePause, 0)
    }

    func testManualPauseWhilePaused() {
        var entry = TimeEntry(startTime: Date(), status: .paused)
        entry.manualPauseSeconds = 300
        entry.pauseStartedAt = Date().addingTimeInterval(-120)  // 2 min in current pause

        // totalManualPause should include both accumulated + current
        XCTAssertGreaterThan(entry.totalManualPause, 300)
        XCTAssertLessThan(entry.totalManualPause, 500)  // ~420
    }

    func testDefaultInitValues() {
        let entry = TimeEntry(startTime: Date())
        XCTAssertEqual(entry.status, .running)
        XCTAssertNil(entry.endTime)
        XCTAssertEqual(entry.manualPauseSeconds, 0)
        XCTAssertNil(entry.pauseStartedAt)
        XCTAssertTrue(entry.idleDecisions.isEmpty)
        XCTAssertTrue(entry.notifiedThresholds.isEmpty)
        XCTAssertEqual(entry.note, "")
    }
}

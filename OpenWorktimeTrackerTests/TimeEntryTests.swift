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
}

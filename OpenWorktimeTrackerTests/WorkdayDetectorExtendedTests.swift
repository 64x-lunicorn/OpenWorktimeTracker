import XCTest

@testable import OpenWorktimeTracker

/// Extended tests for WorkdayDetector covering edge cases and bug fixes.
final class WorkdayDetectorExtendedTests: XCTestCase {

    private let calendar = Calendar.current

    // MARK: - Helpers

    private func makeEntry(
        dateString: String,
        status: TimeEntry.Status,
        startTime: Date? = nil,
        endTime: Date? = nil,
        idleDecisions: [IdleDecision] = []
    ) -> TimeEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: dateString) ?? Date()
        var entry = TimeEntry(
            date: dateString,
            startTime: startTime ?? date,
            endTime: endTime,
            status: status
        )
        entry.idleDecisions = idleDecisions
        return entry
    }

    // MARK: - suggestEndTime via evaluate (indirect)

    func testEndPreviousUsesIdleDecisionEndTime() {
        let detector = WorkdayDetector()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayString = TimeEntry.dateString(from: yesterday)

        let idleStart = calendar.date(
            bySettingHour: 17, minute: 30, second: 0, of: yesterday)!
        let idleEnd = calendar.date(
            bySettingHour: 18, minute: 0, second: 0, of: yesterday)!

        let entry = makeEntry(
            dateString: yesterdayString,
            status: .running,
            startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: yesterday),
            idleDecisions: [
                IdleDecision(idleStart: idleStart, idleEnd: idleEnd, decision: .pause)
            ]
        )

        let action = detector.evaluate(todayEntry: nil, mostRecentEntry: entry)

        if case .endPreviousAndStartNew(_, let suggestedEnd) = action {
            // Should suggest idleStart (17:30) not 18:00 default
            XCTAssertEqual(suggestedEnd, idleStart)
        } else {
            XCTFail("Expected .endPreviousAndStartNew, got \(action)")
        }
    }

    func testSuggestedEndTimeNeverBeforeStartTime() {
        // Entry started at 20:00 — default 18:00 would be before start
        let detector = WorkdayDetector()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayString = TimeEntry.dateString(from: yesterday)

        let lateStart = calendar.date(
            bySettingHour: 20, minute: 0, second: 0, of: yesterday)!

        let entry = makeEntry(
            dateString: yesterdayString,
            status: .running,
            startTime: lateStart
        )

        let action = detector.evaluate(todayEntry: nil, mostRecentEntry: entry)

        if case .endPreviousAndStartNew(_, let suggestedEnd) = action {
            // Bug fix: suggestedEnd must be >= startTime
            XCTAssertGreaterThanOrEqual(suggestedEnd, lateStart)
        } else {
            XCTFail("Expected .endPreviousAndStartNew, got \(action)")
        }
    }

    // MARK: - effectiveDateString edge cases

    func testEffectiveDateAtExactlyNewDayHour() {
        let detector = WorkdayDetector(newDayStartHour: 4)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 4
        components.minute = 0
        components.second = 0
        let dateAt4AM = calendar.date(from: components)!

        let effective = detector.effectiveDateString(for: dateAt4AM)
        // At exactly 4 AM, hour == newDayStartHour, so NOT < 4, so it's "today"
        let expectedDate = TimeEntry.dateString(from: dateAt4AM)
        XCTAssertEqual(effective, expectedDate)
    }

    func testEffectiveDateAtMidnight() {
        let detector = WorkdayDetector(newDayStartHour: 4)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0
        components.minute = 0
        components.second = 0
        let midnight = calendar.date(from: components)!

        let effective = detector.effectiveDateString(for: midnight)
        // Midnight (0 < 4) → still yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: midnight)!
        let expectedDate = TimeEntry.dateString(from: yesterday)
        XCTAssertEqual(effective, expectedDate)
    }

    func testEffectiveDateWithCustomNewDayHour() {
        let detector = WorkdayDetector(newDayStartHour: 6)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 5
        components.minute = 59
        let date559AM = calendar.date(from: components)!

        let effective = detector.effectiveDateString(for: date559AM)
        // 5 < 6, so still yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date559AM)!
        let expectedDate = TimeEntry.dateString(from: yesterday)
        XCTAssertEqual(effective, expectedDate)
    }

    // MARK: - Paused entry from previous day

    func testEndPreviousPausedEntry() {
        let detector = WorkdayDetector()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayString = TimeEntry.dateString(from: yesterday)

        let entry = makeEntry(dateString: yesterdayString, status: .paused)
        let action = detector.evaluate(todayEntry: nil, mostRecentEntry: entry)

        if case .endPreviousAndStartNew(let prev, _) = action {
            XCTAssertEqual(prev.status, .paused)
        } else {
            XCTFail("Expected .endPreviousAndStartNew, got \(action)")
        }
    }

    // MARK: - Today entry takes priority over most recent

    func testTodayEntryTakesPriorityOverMostRecent() {
        let detector = WorkdayDetector()
        let todayString = TimeEntry.dateString(from: Date())

        let todayEntry = makeEntry(dateString: todayString, status: .running)
        let oldEntry = makeEntry(dateString: "2099-01-01", status: .running)

        let action = detector.evaluate(todayEntry: todayEntry, mostRecentEntry: oldEntry)

        if case .continueExisting(let entry) = action {
            XCTAssertEqual(entry.date, todayString)
        } else {
            XCTFail("Expected .continueExisting, got \(action)")
        }
    }
}

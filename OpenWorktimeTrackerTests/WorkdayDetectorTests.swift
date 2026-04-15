import XCTest

@testable import OpenWorktimeTracker

final class WorkdayDetectorTests: XCTestCase {

    private let calendar = Calendar.current

    // MARK: - Helpers

    private func makeEntry(
        dateString: String,
        status: TimeEntry.Status,
        startTime: Date? = nil
    ) -> TimeEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: dateString) ?? Date()
        return TimeEntry(
            date: dateString,
            startTime: startTime ?? date,
            status: status
        )
    }

    private func todayString() -> String {
        TimeEntry.dateString(from: Date())
    }

    private func yesterdayString() -> String {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return TimeEntry.dateString(from: yesterday)
    }

    // MARK: - Start Fresh Day

    func testStartFreshWhenNoEntries() {
        let detector = WorkdayDetector()
        let action = detector.evaluate(todayEntry: nil, mostRecentEntry: nil)

        if case .startFreshDay = action {
            // Expected
        } else {
            XCTFail("Expected .startFreshDay, got \(action)")
        }
    }

    func testStartFreshWhenPreviousDayEnded() {
        let detector = WorkdayDetector()
        let yesterday = makeEntry(dateString: yesterdayString(), status: .ended)
        let action = detector.evaluate(todayEntry: nil, mostRecentEntry: yesterday)

        if case .startFreshDay = action {
            // Expected
        } else {
            XCTFail("Expected .startFreshDay, got \(action)")
        }
    }

    // MARK: - Continue Existing

    func testContinueExistingRunningEntry() {
        let detector = WorkdayDetector()
        let today = makeEntry(dateString: todayString(), status: .running)
        let action = detector.evaluate(todayEntry: today, mostRecentEntry: today)

        if case .continueExisting(let entry) = action {
            XCTAssertEqual(entry.status, .running)
        } else {
            XCTFail("Expected .continueExisting, got \(action)")
        }
    }

    func testContinueExistingPausedEntry() {
        let detector = WorkdayDetector()
        let today = makeEntry(dateString: todayString(), status: .paused)
        let action = detector.evaluate(todayEntry: today, mostRecentEntry: today)

        if case .continueExisting(let entry) = action {
            XCTAssertEqual(entry.status, .paused)
        } else {
            XCTFail("Expected .continueExisting, got \(action)")
        }
    }

    // MARK: - Day Already Ended

    func testDayAlreadyEnded() {
        let detector = WorkdayDetector()
        let today = makeEntry(dateString: todayString(), status: .ended)
        let action = detector.evaluate(todayEntry: today, mostRecentEntry: today)

        if case .dayAlreadyEnded = action {
            // Expected
        } else {
            XCTFail("Expected .dayAlreadyEnded, got \(action)")
        }
    }

    // MARK: - End Previous and Start New

    func testEndPreviousRunningEntry() {
        let detector = WorkdayDetector()
        let yesterday = makeEntry(dateString: yesterdayString(), status: .running)
        let action = detector.evaluate(todayEntry: nil, mostRecentEntry: yesterday)

        if case .endPreviousAndStartNew(let prev, _) = action {
            XCTAssertEqual(prev.date, yesterdayString())
        } else {
            XCTFail("Expected .endPreviousAndStartNew, got \(action)")
        }
    }

    // MARK: - Effective Date

    func testEffectiveDateBefore4AM() {
        let detector = WorkdayDetector(newDayStartHour: 4)
        // 3 AM should be "yesterday"
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 3
        components.minute = 0
        let date3AM = calendar.date(from: components)!

        let effective = detector.effectiveDateString(for: date3AM)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date3AM)!
        let expectedDate = TimeEntry.dateString(from: yesterday)

        XCTAssertEqual(effective, expectedDate)
    }

    func testEffectiveDateAfter4AM() {
        let detector = WorkdayDetector(newDayStartHour: 4)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 5
        components.minute = 0
        let date5AM = calendar.date(from: components)!

        let effective = detector.effectiveDateString(for: date5AM)
        let expectedDate = TimeEntry.dateString(from: date5AM)

        XCTAssertEqual(effective, expectedDate)
    }
}

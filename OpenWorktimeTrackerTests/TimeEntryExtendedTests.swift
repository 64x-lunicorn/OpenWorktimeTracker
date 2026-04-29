import XCTest

@testable import OpenWorktimeTracker

/// Extended tests for TimeEntry covering edge cases and computed properties.
final class TimeEntryExtendedTests: XCTestCase {

    // MARK: - IdleDecision

    func testIdleDecisionDuration() {
        let start = Date()
        let end = start.addingTimeInterval(900)  // 15 min
        let decision = IdleDecision(idleStart: start, idleEnd: end, decision: .pause)
        XCTAssertEqual(decision.duration, 900, accuracy: 0.01)
    }

    func testIdleDecisionCodableRoundTrip() throws {
        let original = IdleDecision(
            idleStart: Date(),
            idleEnd: Date().addingTimeInterval(600),
            decision: .work
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(IdleDecision.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.decision, .work)
        XCTAssertEqual(decoded.duration, original.duration, accuracy: 1)
    }

    func testIdleDecisionDecisionIsMutable() {
        var decision = IdleDecision(
            idleStart: Date(),
            idleEnd: Date().addingTimeInterval(600),
            decision: .work
        )
        decision.decision = .pause
        XCTAssertEqual(decision.decision, .pause)
    }

    // MARK: - TimeEntry Codable

    func testTimeEntryCodableRoundTrip() throws {
        var original = TimeEntry(
            date: "2099-12-01",
            startTime: Date(),
            endTime: Date().addingTimeInterval(8 * 3600),
            status: .ended,
            manualPauseSeconds: 1800,
            note: "Full day"
        )
        original.notifiedThresholds = ["normal", "critical"]
        original.idleDecisions = [
            IdleDecision(
                idleStart: Date().addingTimeInterval(3600),
                idleEnd: Date().addingTimeInterval(4200),
                decision: .pause
            )
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TimeEntry.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.date, "2099-12-01")
        XCTAssertEqual(decoded.status, .ended)
        XCTAssertEqual(decoded.manualPauseSeconds, 1800)
        XCTAssertEqual(decoded.note, "Full day")
        XCTAssertEqual(decoded.notifiedThresholds, ["normal", "critical"])
        XCTAssertEqual(decoded.idleDecisions.count, 1)
        XCTAssertEqual(decoded.idleDecisions[0].decision, .pause)
    }

    func testTimeEntryCodableWithNilEndTime() throws {
        let original = TimeEntry(date: "2099-12-02", startTime: Date(), status: .running)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TimeEntry.self, from: data)

        XCTAssertNil(decoded.endTime)
        XCTAssertEqual(decoded.status, .running)
    }

    func testTimeEntryCodableWithPauseStartedAt() throws {
        var original = TimeEntry(date: "2099-12-03", startTime: Date(), status: .paused)
        original.pauseStartedAt = Date()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TimeEntry.self, from: data)

        XCTAssertNotNil(decoded.pauseStartedAt)
        XCTAssertEqual(decoded.status, .paused)
    }

    // MARK: - grossTime Edge Cases

    func testGrossTimeWithEndTimeAtStartTime() {
        let now = Date()
        let entry = TimeEntry(startTime: now, endTime: now)
        XCTAssertEqual(entry.grossTime, 0)
    }

    func testGrossTimeWithOngoingEntry() {
        let start = Date().addingTimeInterval(-3600)  // Started 1h ago
        let entry = TimeEntry(startTime: start)
        // Should use Date() as end — grossTime ≈ 3600
        XCTAssertGreaterThan(entry.grossTime, 3500)
        XCTAssertLessThan(entry.grossTime, 3700)
    }

    // MARK: - totalPause Edge Cases

    func testTotalPauseWithMultipleIdleDecisions() {
        let start = Date()
        var entry = TimeEntry(
            startTime: start,
            endTime: start.addingTimeInterval(10 * 3600)
        )
        entry.manualPauseSeconds = 600  // 10 min
        entry.idleDecisions = [
            IdleDecision(
                idleStart: start.addingTimeInterval(3600),
                idleEnd: start.addingTimeInterval(4500),
                decision: .pause  // 15 min
            ),
            IdleDecision(
                idleStart: start.addingTimeInterval(7200),
                idleEnd: start.addingTimeInterval(7800),
                decision: .work  // Should not count
            ),
            IdleDecision(
                idleStart: start.addingTimeInterval(9000),
                idleEnd: start.addingTimeInterval(9600),
                decision: .pause  // 10 min
            ),
        ]

        // Manual: 600 + Idle pause: 900 + 600 = 1500, total = 2100
        XCTAssertEqual(entry.totalManualPause, 600)
        XCTAssertEqual(entry.totalIdlePause, 1500, accuracy: 1)
        XCTAssertEqual(entry.totalPause, 2100, accuracy: 1)
    }

    // MARK: - dateString

    func testDateStringConsistency() {
        let date = Date()
        let str1 = TimeEntry.dateString(from: date)
        let str2 = TimeEntry.dateString(from: date)
        XCTAssertEqual(str1, str2)
    }

    func testDateStringFormat() {
        let str = TimeEntry.dateString(from: Date())
        // Should match YYYY-MM-DD
        let regex = try! NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$")
        let range = NSRange(str.startIndex..., in: str)
        XCTAssertNotNil(regex.firstMatch(in: str, range: range))
    }

    // MARK: - workTimeBeforeAutoBreak

    func testWorkTimeBeforeAutoBreakWithLargePause() {
        let start = Date()
        var entry = TimeEntry(
            startTime: start,
            endTime: start.addingTimeInterval(3600)  // 1h
        )
        entry.manualPauseSeconds = 7200  // 2h (more than gross)

        // Should be max(0, ...) = 0
        XCTAssertEqual(entry.workTimeBeforeAutoBreak, 0)
    }

    // MARK: - Status raw values

    func testStatusRawValues() {
        XCTAssertEqual(TimeEntry.Status.running.rawValue, "running")
        XCTAssertEqual(TimeEntry.Status.paused.rawValue, "paused")
        XCTAssertEqual(TimeEntry.Status.ended.rawValue, "ended")
    }
}

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

    func testDateStringMatchesPattern() {
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

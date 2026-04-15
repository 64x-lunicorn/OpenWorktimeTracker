import XCTest

@testable import OpenWorktimeTracker

final class PersistenceManagerTests: XCTestCase {

    private var manager: PersistenceManager!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        // Use a temp directory for tests
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OWT_Tests_\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        manager = PersistenceManager()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Round-Trip

    func testSaveAndLoadEntry() {
        let entry = TimeEntry(
            date: "2026-04-15",
            startTime: Date(),
            status: .running,
            note: "Test entry"
        )

        manager.save(entry)

        let loaded = manager.load(for: "2026-04-15")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, entry.id)
        XCTAssertEqual(loaded?.date, "2026-04-15")
        XCTAssertEqual(loaded?.status, .running)
        XCTAssertEqual(loaded?.note, "Test entry")
    }

    func testSaveAndLoadWithIdleDecisions() {
        var entry = TimeEntry(date: "2026-04-15", startTime: Date())
        entry.idleDecisions = [
            IdleDecision(
                idleStart: Date().addingTimeInterval(-900),
                idleEnd: Date(),
                decision: .pause
            ),
            IdleDecision(
                idleStart: Date().addingTimeInterval(-1800),
                idleEnd: Date().addingTimeInterval(-900),
                decision: .work
            ),
        ]

        manager.save(entry)

        let loaded = manager.load(for: "2026-04-15")
        XCTAssertEqual(loaded?.idleDecisions.count, 2)
        XCTAssertEqual(loaded?.idleDecisions[0].decision, .pause)
        XCTAssertEqual(loaded?.idleDecisions[1].decision, .work)
    }

    func testLoadNonExistentEntry() {
        let loaded = manager.load(for: "1999-01-01")
        XCTAssertNil(loaded)
    }

    // MARK: - Status

    func testSaveEntryWithEndedStatus() {
        var entry = TimeEntry(date: "2026-04-15", startTime: Date())
        entry.status = .ended
        entry.endTime = Date()

        manager.save(entry)

        let loaded = manager.load(for: "2026-04-15")
        XCTAssertEqual(loaded?.status, .ended)
        XCTAssertNotNil(loaded?.endTime)
    }

    // MARK: - Notified Thresholds

    func testNotifiedThresholdsRoundTrip() {
        var entry = TimeEntry(date: "2026-04-15", startTime: Date())
        entry.notifiedThresholds = ["normal", "critical"]

        manager.save(entry)

        let loaded = manager.load(for: "2026-04-15")
        XCTAssertEqual(loaded?.notifiedThresholds, ["normal", "critical"])
    }
}

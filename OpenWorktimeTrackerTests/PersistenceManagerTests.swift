import XCTest

@testable import OpenWorktimeTracker

final class PersistenceManagerTests: XCTestCase {

    private var manager: PersistenceManager!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OWT_Tests_\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        manager = PersistenceManager(logDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Round-Trip

    func testSaveAndLoadEntry() {
        let entry = TimeEntry(
            date: "2099-01-01",
            startTime: Date(),
            status: .running,
            note: "Test entry"
        )

        manager.save(entry)
        manager.flush()

        let loaded = manager.load(for: "2099-01-01")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, entry.id)
        XCTAssertEqual(loaded?.date, "2099-01-01")
        XCTAssertEqual(loaded?.status, .running)
        XCTAssertEqual(loaded?.note, "Test entry")
    }

    func testSaveAndLoadWithIdleDecisions() {
        var entry = TimeEntry(date: "2099-01-01", startTime: Date())
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
        manager.flush()

        let loaded = manager.load(for: "2099-01-01")
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
        var entry = TimeEntry(date: "2099-01-01", startTime: Date())
        entry.status = .ended
        entry.endTime = Date()

        manager.save(entry)
        manager.flush()

        let loaded = manager.load(for: "2099-01-01")
        XCTAssertEqual(loaded?.status, .ended)
        XCTAssertNotNil(loaded?.endTime)
    }

    // MARK: - Notified Thresholds

    func testNotifiedThresholdsRoundTrip() {
        var entry = TimeEntry(date: "2099-01-01", startTime: Date())
        entry.notifiedThresholds = ["normal", "critical"]

        manager.save(entry)
        manager.flush()

        let loaded = manager.load(for: "2099-01-01")
        XCTAssertEqual(loaded?.notifiedThresholds, ["normal", "critical"])
    }

    // MARK: - Overwrite

    func testSaveOverwritesExistingEntry() {
        let entry1 = TimeEntry(date: "2099-01-02", startTime: Date(), note: "First")
        manager.save(entry1)
        manager.flush()

        let entry2 = TimeEntry(
            id: entry1.id,
            date: "2099-01-02",
            startTime: entry1.startTime,
            note: "Updated"
        )
        manager.save(entry2)
        manager.flush()

        let loaded = manager.load(for: "2099-01-02")
        XCTAssertEqual(loaded?.note, "Updated")
    }

    // MARK: - Multiple Days

    func testLoadDifferentDays() {
        let entry1 = TimeEntry(date: "2099-01-02", startTime: Date(), note: "Day 1")
        let entry2 = TimeEntry(date: "2099-01-03", startTime: Date(), note: "Day 2")

        manager.save(entry1)
        manager.save(entry2)
        manager.flush()

        let loaded1 = manager.load(for: "2099-01-02")
        let loaded2 = manager.load(for: "2099-01-03")
        XCTAssertEqual(loaded1?.note, "Day 1")
        XCTAssertEqual(loaded2?.note, "Day 2")
    }
}

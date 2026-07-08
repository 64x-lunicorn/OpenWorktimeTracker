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
            )
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

    // MARK: - Delete

    func testDeleteRemovesFile() {
        let entry = TimeEntry(date: "2099-03-01", startTime: Date(), note: "To delete")
        manager.save(entry)
        manager.flush()

        XCTAssertNotNil(manager.load(for: "2099-03-01"))

        manager.delete(for: "2099-03-01")

        XCTAssertNil(manager.load(for: "2099-03-01"))
    }

    func testDeleteNonExistentFileDoesNotCrash() {
        manager.delete(for: "1999-12-31")
    }

    // MARK: - Load All

    func testLoadAllReturnsAllEntries() {
        manager.save(TimeEntry(date: "2099-04-01", startTime: Date()))
        manager.save(TimeEntry(date: "2099-04-02", startTime: Date()))
        manager.save(TimeEntry(date: "2099-04-03", startTime: Date()))
        manager.flush()

        XCTAssertEqual(manager.loadAll().count, 3)
    }

    func testLoadAllReturnsSortedByDateDesc() {
        manager.save(TimeEntry(date: "2099-04-01", startTime: Date()))
        manager.save(TimeEntry(date: "2099-04-03", startTime: Date()))
        manager.save(TimeEntry(date: "2099-04-02", startTime: Date()))
        manager.flush()

        let all = manager.loadAll()
        XCTAssertEqual(all[0].date, "2099-04-03")
        XCTAssertEqual(all[1].date, "2099-04-02")
        XCTAssertEqual(all[2].date, "2099-04-01")
    }

    func testLoadAllEmptyDirectory() {
        XCTAssertTrue(manager.loadAll().isEmpty)
    }

    // MARK: - Load Last Days

    func testLoadLastDaysReturnsLimitedCount() {
        for i in 1...5 {
            manager.save(TimeEntry(date: "2099-05-0\(i)", startTime: Date()))
        }
        manager.flush()

        let last3 = manager.loadLastDays(3)
        XCTAssertEqual(last3.count, 3)
        XCTAssertEqual(last3[0].date, "2099-05-05")
        XCTAssertEqual(last3[1].date, "2099-05-04")
        XCTAssertEqual(last3[2].date, "2099-05-03")
    }

    func testLoadLastDaysWithFewerEntriesThanRequested() {
        manager.save(TimeEntry(date: "2099-06-01", startTime: Date()))
        manager.flush()

        XCTAssertEqual(manager.loadLastDays(5).count, 1)
    }

    // MARK: - Load Most Recent

    func testLoadMostRecentEntry() {
        manager.save(TimeEntry(date: "2099-07-01", startTime: Date()))
        manager.save(TimeEntry(date: "2099-07-15", startTime: Date()))
        manager.save(TimeEntry(date: "2099-07-10", startTime: Date()))
        manager.flush()

        XCTAssertEqual(manager.loadMostRecentEntry()?.date, "2099-07-15")
    }

    func testLoadMostRecentEntryEmpty() {
        XCTAssertNil(manager.loadMostRecentEntry())
    }

    // MARK: - Save Overwrite Preserves ID

    func testSaveOverwritePreservesIDButUpdatesContent() {
        let id = UUID()
        let entry1 = TimeEntry(id: id, date: "2099-08-01", startTime: Date(), note: "Original")
        manager.save(entry1)
        manager.flush()

        var entry2 = entry1
        entry2.note = "Modified"
        manager.save(entry2)
        manager.flush()

        let loaded = manager.load(for: "2099-08-01")
        XCTAssertEqual(loaded?.id, id)
        XCTAssertEqual(loaded?.note, "Modified")
    }

    // MARK: - Export CSV

    func testExportCSVWithEntries() {
        var entry = TimeEntry(
            date: "2099-09-01",
            startTime: Date(),
            endTime: Date().addingTimeInterval(8 * 3600),
            status: .ended,
            note: "Test note"
        )
        entry.manualPauseSeconds = 900  // 15min
        manager.save(entry)
        manager.flush()

        let csvURL = manager.exportCSV()
        XCTAssertNotNil(csvURL)

        if let url = csvURL {
            let content = try? String(contentsOf: url, encoding: .utf8)
            XCTAssertNotNil(content)
            XCTAssertTrue(content?.contains("2099-09-01") ?? false)
            XCTAssertTrue(content?.contains("Test note") ?? false)
        }
    }

    func testExportCSVEmpty() {
        XCTAssertNil(manager.exportCSV())
    }

    // MARK: - Corrupt File Handling

    func testLoadIgnoresCorruptFile() {
        let corruptURL = tempDir.appendingPathComponent("2099-10-01.json")
        try? "not valid json".write(to: corruptURL, atomically: true, encoding: .utf8)

        XCTAssertNil(manager.load(for: "2099-10-01"))
    }

    func testLoadAllSkipsCorruptFiles() {
        manager.save(TimeEntry(date: "2099-10-02", startTime: Date()))
        manager.flush()

        let corruptURL = tempDir.appendingPathComponent("2099-10-03.json")
        try? "broken".write(to: corruptURL, atomically: true, encoding: .utf8)

        let all = manager.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].date, "2099-10-02")
    }

    // MARK: - Concurrent Save

    func testConcurrentSavesDoNotCrash() {
        let expectation = expectation(description: "concurrent saves")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                let entry = TimeEntry(
                    date: "2099-11-\(String(format: "%02d", i + 1))", startTime: Date())
                self.manager.save(entry)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
        manager.flush()

        XCTAssertEqual(manager.loadAll().count, 10)
    }
}

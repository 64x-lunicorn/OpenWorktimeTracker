import XCTest

@testable import OpenWorktimeTracker

/// Tests for PersistenceManager.delete(), loadAll(), loadLastDays(), and edge cases.
final class PersistenceManagerExtendedTests: XCTestCase {

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
        // Should not throw or crash
        manager.delete(for: "1999-12-31")
    }

    // MARK: - Load All

    func testLoadAllReturnsAllEntries() {
        let entry1 = TimeEntry(date: "2099-04-01", startTime: Date())
        let entry2 = TimeEntry(date: "2099-04-02", startTime: Date())
        let entry3 = TimeEntry(date: "2099-04-03", startTime: Date())

        manager.save(entry1)
        manager.save(entry2)
        manager.save(entry3)
        manager.flush()

        let all = manager.loadAll()
        XCTAssertEqual(all.count, 3)
    }

    func testLoadAllReturnsSortedByDateDesc() {
        let entry1 = TimeEntry(date: "2099-04-01", startTime: Date())
        let entry2 = TimeEntry(date: "2099-04-03", startTime: Date())
        let entry3 = TimeEntry(date: "2099-04-02", startTime: Date())

        manager.save(entry1)
        manager.save(entry2)
        manager.save(entry3)
        manager.flush()

        let all = manager.loadAll()
        XCTAssertEqual(all[0].date, "2099-04-03")
        XCTAssertEqual(all[1].date, "2099-04-02")
        XCTAssertEqual(all[2].date, "2099-04-01")
    }

    func testLoadAllEmptyDirectory() {
        let all = manager.loadAll()
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Load Last Days

    func testLoadLastDaysReturnsLimitedCount() {
        for i in 1...5 {
            let entry = TimeEntry(
                date: "2099-05-0\(i)", startTime: Date())
            manager.save(entry)
        }
        manager.flush()

        let last3 = manager.loadLastDays(3)
        XCTAssertEqual(last3.count, 3)
        // Should be most recent first
        XCTAssertEqual(last3[0].date, "2099-05-05")
        XCTAssertEqual(last3[1].date, "2099-05-04")
        XCTAssertEqual(last3[2].date, "2099-05-03")
    }

    func testLoadLastDaysWithFewerEntriesThanRequested() {
        let entry = TimeEntry(date: "2099-06-01", startTime: Date())
        manager.save(entry)
        manager.flush()

        let last5 = manager.loadLastDays(5)
        XCTAssertEqual(last5.count, 1)
    }

    // MARK: - Load Most Recent

    func testLoadMostRecentEntry() {
        let entry1 = TimeEntry(date: "2099-07-01", startTime: Date())
        let entry2 = TimeEntry(date: "2099-07-15", startTime: Date())
        let entry3 = TimeEntry(date: "2099-07-10", startTime: Date())

        manager.save(entry1)
        manager.save(entry2)
        manager.save(entry3)
        manager.flush()

        let recent = manager.loadMostRecentEntry()
        XCTAssertEqual(recent?.date, "2099-07-15")
    }

    func testLoadMostRecentEntryEmpty() {
        let recent = manager.loadMostRecentEntry()
        XCTAssertNil(recent)
    }

    // MARK: - Save Overwrites

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
        let csvURL = manager.exportCSV()
        XCTAssertNil(csvURL)
    }

    // MARK: - Corrupt File Handling

    func testLoadIgnoresCorruptFile() {
        let corruptURL = tempDir.appendingPathComponent("2099-10-01.json")
        try? "not valid json".write(to: corruptURL, atomically: true, encoding: .utf8)

        let loaded = manager.load(for: "2099-10-01")
        XCTAssertNil(loaded)
    }

    func testLoadAllSkipsCorruptFiles() {
        // Save a valid entry
        let entry = TimeEntry(date: "2099-10-02", startTime: Date())
        manager.save(entry)
        manager.flush()

        // Add a corrupt file
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
                let entry = TimeEntry(date: "2099-11-\(String(format: "%02d", i + 1))", startTime: Date())
                self.manager.save(entry)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
        manager.flush()

        let all = manager.loadAll()
        XCTAssertEqual(all.count, 10)
    }
}

import XCTest

@testable import OpenWorktimeTracker

final class WidgetSnapshotTests: XCTestCase {
    private let measuredAt = Date(timeIntervalSince1970: 1_800_000_000)
    private var defaults: UserDefaults!
    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        let suiteName = "widget-snapshot-tests-\(UUID())"
        defaults = UserDefaults(suiteName: suiteName)!
        let suite = defaults!
        addTeardownBlock { suite.removePersistentDomain(forName: suiteName) }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-snapshot-tests-\(UUID())", isDirectory: true)
        fileURL = directory.appendingPathComponent("widget-state.json")
        addTeardownBlock {
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
            }
        }
    }

    private func snapshot(
        state: WorkdayState = .running, netTime: TimeInterval = 3600,
        thresholdLadder: ThresholdLadder = ThresholdLadder(elevatedHours: 7.5, criticalHours: 9)
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            measuredAt: measuredAt, state: state, netTime: netTime, grossTime: 4200,
            startTime: measuredAt.addingTimeInterval(-4200), workDate: "2027-01-15",
            targetHours: 7, thresholdLadder: thresholdLadder)
    }

    func testDefaultsRoundTripReplacesOneCompleteValue() throws {
        let writer = SharedDefaults(defaults: defaults, fallbackURL: fileURL)
        let reader = SharedDefaults(defaults: defaults, fallbackURL: fileURL)
        let first = snapshot()
        try writer.publish(first)
        XCTAssertEqual(try reader.readSnapshot(), first)

        let second = WidgetSnapshot(
            measuredAt: measuredAt.addingTimeInterval(900), state: .ended, netTime: 4500,
            grossTime: 5100, startTime: first.startTime, workDate: first.workDate,
            targetHours: 8, thresholdLadder: ThresholdLadder(elevatedHours: 8, criticalHours: 9.5))
        try writer.publish(second)

        XCTAssertEqual(try reader.readSnapshot(), second)
        XCTAssertEqual(
            Set(defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("widget_") }),
            [SharedDefaults.snapshotKey])
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testFileFallbackRoundTripAndReplacement() throws {
        let writer = SharedDefaults(defaults: nil, fallbackURL: fileURL)
        let reader = SharedDefaults(defaults: nil, fallbackURL: fileURL)
        XCTAssertNil(try reader.readSnapshot())
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.deletingLastPathComponent().path))

        try writer.publish(snapshot())
        XCTAssertEqual(try reader.readSnapshot(), snapshot())
        try writer.publish(snapshot(state: .paused))
        XCTAssertEqual(try reader.readSnapshot(), snapshot(state: .paused))
    }

    func testLegacyKeysAreNotCombinedIntoAnUnmeasuredSnapshot() throws {
        defaults.set("running", forKey: "widget_state")
        defaults.set(3600, forKey: "widget_netTime")
        let store = SharedDefaults(defaults: defaults, fallbackURL: fileURL)

        XCTAssertNil(try store.readSnapshot())
        try store.publish(snapshot(state: .ended))
        XCTAssertEqual(try store.readSnapshot(), snapshot(state: .ended))
    }

    func testCorruptDefaultsReportsFailureRatherThanReadingLegacyFields() {
        defaults.set(Data("broken".utf8), forKey: SharedDefaults.snapshotKey)
        defaults.set("running", forKey: "widget_state")
        let store = SharedDefaults(defaults: defaults, fallbackURL: fileURL)

        XCTAssertThrowsError(try store.readSnapshot())
        defaults.set("wrong type", forKey: SharedDefaults.snapshotKey)
        XCTAssertThrowsError(try store.readSnapshot())
    }

    func testCorruptFileReportsFailure() throws {
        let store = SharedDefaults(defaults: nil, fallbackURL: fileURL)
        try store.publish(snapshot())
        try Data("broken".utf8).write(to: fileURL)

        XCTAssertThrowsError(try store.readSnapshot())
    }

    func testFailedFilePublicationIsReported() throws {
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        let store = SharedDefaults(defaults: nil, fallbackURL: fileURL)

        XCTAssertThrowsError(try store.publish(snapshot()))
    }

    func testInvalidPublicationPreservesPreviousSnapshot() throws {
        let store = SharedDefaults(defaults: defaults, fallbackURL: fileURL)
        try store.publish(snapshot())
        for value in [TimeInterval.nan, .infinity, -1] {
            XCTAssertThrowsError(try store.publish(snapshot(netTime: value)))
            XCTAssertEqual(try store.readSnapshot(), snapshot())
        }
        for ladder in [
            ThresholdLadder(elevatedHours: .nan, criticalHours: 9),
            ThresholdLadder(elevatedHours: 8, criticalHours: -1)
        ] {
            XCTAssertThrowsError(try store.publish(snapshot(thresholdLadder: ladder)))
            XCTAssertEqual(try store.readSnapshot(), snapshot())
        }
    }

    func testInvalidDecodedSnapshotIsRejected() throws {
        let encoded = try JSONEncoder().encode(snapshot(netTime: -1))
        defaults.set(encoded, forKey: SharedDefaults.snapshotKey)

        XCTAssertThrowsError(try SharedDefaults(defaults: defaults).readSnapshot())
    }

    func testUnknownDecodedStateIsRejected() throws {
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot())) as? [String: Any])
        object["state"] = "unknown"
        defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: SharedDefaults.snapshotKey)

        XCTAssertThrowsError(try SharedDefaults(defaults: defaults).readSnapshot())
    }

    /// The layout published by v0.7.0 and earlier, with colour-named thresholds.
    private struct PreviousVersionSnapshot: Encodable {
        let measuredAt: Date
        let state: String
        let netTime: TimeInterval
        let grossTime: TimeInterval
        let startTime: Date?
        let workDate: String
        let targetHours: Double
        let orangeThreshold: Double
        let redThreshold: Double
    }

    /// Chosen behaviour: a snapshot left under the previous version's key is
    /// ignored rather than migrated, without reporting a read failure. The widget
    /// shows its "no current data" state until the updated app publishes, which
    /// it does on launch and every tick, and publishing removes the stale value.
    func testPreviousVersionSnapshotIsUnavailableUntilNextPublish() throws {
        let previous = PreviousVersionSnapshot(
            measuredAt: measuredAt, state: "running", netTime: 3600, grossTime: 4200,
            startTime: measuredAt.addingTimeInterval(-4200), workDate: "2027-01-15",
            targetHours: 7, orangeThreshold: 7.5, redThreshold: 9)
        defaults.set(try JSONEncoder().encode(previous), forKey: "widget_snapshot_v1")
        let store = SharedDefaults(defaults: defaults, fallbackURL: fileURL)

        XCTAssertNil(try store.readSnapshot())
        try store.publish(snapshot())
        XCTAssertEqual(try store.readSnapshot(), snapshot())
        XCTAssertNil(defaults.object(forKey: "widget_snapshot_v1"))
    }

    func testDelayedReadKeepsRunningTimerAnchoredToMeasurement() {
        let value = snapshot()
        let readAt = measuredAt.addingTimeInterval(900)

        XCTAssertEqual(value.liveNetStart, measuredAt.addingTimeInterval(-3600))
        XCTAssertEqual(value.netTime(at: readAt), 4500)
        XCTAssertEqual(readAt.timeIntervalSince(value.liveNetStart), value.netTime(at: readAt))
        XCTAssertEqual(value.netTime(at: readAt.addingTimeInterval(300)), 4800)
    }

    func testPausedEndedAndNotStartedSnapshotsDoNotAccumulateTime() {
        for state in [WorkdayState.paused, .ended, .notStarted] {
            let value = snapshot(state: state)
            XCTAssertFalse(value.isRunning)
            XCTAssertEqual(value.netTime(at: measuredAt.addingTimeInterval(86_400)), value.netTime)
        }
    }

    func testProjectionDoesNotSubtractTimeBeforeMeasurement() {
        XCTAssertEqual(snapshot().netTime(at: measuredAt.addingTimeInterval(-600)), 3600)
    }

    func testDelayedThresholdUsesSameElapsedTimeAsTimer() {
        let value = snapshot(netTime: 7 * 3600)

        XCTAssertEqual(value.thresholdLevel(at: measuredAt), .normal)
        XCTAssertEqual(value.thresholdLevel(at: measuredAt.addingTimeInterval(1800)), .elevated)
        XCTAssertEqual(value.thresholdLevel(at: measuredAt.addingTimeInterval(7200)), .critical)
        XCTAssertEqual(
            snapshot(state: .paused, netTime: 7 * 3600)
                .thresholdLevel(at: measuredAt.addingTimeInterval(7200)), .normal)
    }
}

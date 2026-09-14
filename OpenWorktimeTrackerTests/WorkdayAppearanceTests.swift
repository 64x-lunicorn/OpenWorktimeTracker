import XCTest

@testable import OpenWorktimeTracker

final class WorkdayAppearanceTests: XCTestCase {

    func testIndicatorFollowsStateAtNormalLevelAndThresholdLevelAbove() {
        let expected: [WorkdayState: PaletteColor] = [
            .notStarted: .secondary, .running: .green, .paused: .orange, .ended: .blue
        ]
        for state in WorkdayState.allCases {
            XCTAssertEqual(
                WorkdayAppearance(state: state, level: .normal).indicator, expected[state], "\(state)")
            XCTAssertEqual(WorkdayAppearance(state: state, level: .elevated).indicator, .orange, "\(state)")
            XCTAssertEqual(WorkdayAppearance(state: state, level: .critical).indicator, .red, "\(state)")
        }
    }

    func testProgressIsGreenUntilTheThresholdLadderIsReached() {
        let expected: [ThresholdLevel: PaletteColor] = [.normal: .green, .elevated: .orange, .critical: .red]
        for state in WorkdayState.allCases {
            for (level, color) in expected {
                XCTAssertEqual(WorkdayAppearance(state: state, level: level).progress, color, "\(state) \(level)")
            }
        }
    }

    func testLabelsFollowTheStateInEachTarget() {
        let expected: [WorkdayState: (app: String, widget: String)] = [
            .notStarted: ("state.notStarted", "widget.state.idle"),
            .running: ("state.running", "widget.state.running"),
            .paused: ("state.paused", "widget.state.paused"),
            .ended: ("state.ended", "widget.state.ended")
        ]
        for state in WorkdayState.allCases {
            XCTAssertEqual(state.labelKey, expected[state]?.app)
            XCTAssertEqual(state.widgetLabelKey, expected[state]?.widget)
        }
    }

    func testWidgetLabelsExistInEveryWidgetLocalization() throws {
        let widgetDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("WorktimeWidget", isDirectory: true)
        for language in ["de", "en"] {
            let url = widgetDirectory.appendingPathComponent("\(language).lproj/Localizable.strings")
            let table = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], language)
            for state in WorkdayState.allCases {
                XCTAssertNotNil(table[state.widgetLabelKey], "\(language) \(state)")
            }
        }
    }

    func testDurationUsesTwoDigitHours() {
        XCTAssertEqual(TimeInterval(8 * 3600 + 5 * 60).hoursMinutesFormatted, "08:05")
        XCTAssertEqual(TimeInterval(10 * 3600 + 30 * 60 + 59).hoursMinutesFormatted, "10:30")
        XCTAssertEqual(TimeInterval(0).hoursMinutesFormatted, "00:00")
    }

    func testSnapshotAppearanceUsesThresholdLevelAtReadTime() {
        let measuredAt = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = WidgetSnapshot(
            measuredAt: measuredAt, state: .running, netTime: 7.5 * 3600, grossTime: 8 * 3600,
            startTime: nil, workDate: "2027-01-15", targetHours: 8,
            thresholds: ThresholdLadder(elevatedHours: 8, criticalHours: 9.5))

        XCTAssertEqual(snapshot.appearance(at: measuredAt), WorkdayAppearance(state: .running, level: .normal))
        XCTAssertEqual(
            snapshot.appearance(at: measuredAt.addingTimeInterval(1800)),
            WorkdayAppearance(state: .running, level: .elevated))
    }
}

import AppKit
import XCTest

@testable import OpenWorktimeTracker

final class WorkdayAppearanceTests: XCTestCase {

    /// Pins the app's look: these values are what both targets paint with.
    func testPaletteKeepsTheAppsLightAndDarkValues() throws {
        let expected: [PaletteColor: (light: UInt, dark: UInt)] = [
            .blue: (0x0058BC, 0x007AFF),
            .green: (0x006B27, 0x34C759),
            .orange: (0x995000, 0xFF9500),
            .red: (0xBA1A1A, 0xFF453A),
            .secondary: (0x414755, 0xC1C6D7)
        ]
        XCTAssertEqual(Set(expected.keys), Set(PaletteColor.allCases))
        for (paletteColor, values) in expected {
            for (name, hex) in [(NSAppearance.Name.aqua, values.light), (.darkAqua, values.dark)] {
                var resolved: NSColor?
                try XCTUnwrap(NSAppearance(named: name)).performAsCurrentDrawingAppearance {
                    resolved = NSColor(paletteColor.color).usingColorSpace(.sRGB)
                }
                let color = try XCTUnwrap(resolved)
                let actual = UInt((color.redComponent * 255).rounded()) << 16
                    | UInt((color.greenComponent * 255).rounded()) << 8
                    | UInt((color.blueComponent * 255).rounded())
                XCTAssertEqual(
                    String(actual, radix: 16), String(hex, radix: 16), "\(paletteColor) \(name.rawValue)")
            }
        }
    }

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

    func testThresholdLevelAccentIsBlueUntilTheThresholdLadderIsReached() {
        XCTAssertEqual(ThresholdLevel.normal.accent, .blue)
        XCTAssertEqual(ThresholdLevel.elevated.accent, .orange)
        XCTAssertEqual(ThresholdLevel.critical.accent, .red)
    }

    func testMenuBarIsOnlyPaintedAboveTheNormalLevel() {
        XCTAssertNil(ThresholdLevel.normal.menuBarAccent)
        XCTAssertEqual(ThresholdLevel.elevated.menuBarAccent, .orange)
        XCTAssertEqual(ThresholdLevel.critical.menuBarAccent, .red)
    }

    func testDailyLogStatusMapsToTheSameTrackingState() {
        XCTAssertEqual(WorkdayState(TimeEntry.Status.running), .running)
        XCTAssertEqual(WorkdayState(TimeEntry.Status.paused), .paused)
        XCTAssertEqual(WorkdayState(TimeEntry.Status.ended), .ended)
    }

    func testAppLabelsResolveInTheAppBundle() {
        for state in WorkdayState.allCases {
            XCTAssertNotEqual(state.localizedLabel, state.labelKey, "\(state)")
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
            thresholdLadder: ThresholdLadder(elevatedHours: 8, criticalHours: 9.5))

        XCTAssertEqual(snapshot.appearance(at: measuredAt), WorkdayAppearance(state: .running, level: .normal))
        XCTAssertEqual(
            snapshot.appearance(at: measuredAt.addingTimeInterval(1800)),
            WorkdayAppearance(state: .running, level: .elevated))
    }
}

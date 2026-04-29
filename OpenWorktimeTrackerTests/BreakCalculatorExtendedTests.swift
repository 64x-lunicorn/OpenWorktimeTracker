import XCTest

@testable import OpenWorktimeTracker

/// Extended tests for BreakCalculator covering additional edge cases.
final class BreakCalculatorExtendedTests: XCTestCase {

    // MARK: - Negative Input Guards

    func testRequiredBreakNegativeWorkTime() {
        let calc = BreakCalculator()
        // Negative work time should return 0 (hours would be negative)
        XCTAssertEqual(calc.requiredBreak(forWorkTime: -3600), 0)
    }

    func testAutoBreakNegativeAlreadyPaused() {
        let calc = BreakCalculator()
        // Negative alreadyPaused is invalid but shouldn't crash
        let auto = calc.autoBreak(forWorkTime: 7 * 3600, alreadyPaused: -600)
        // required = 30min, max(0, 30min - (-10min)) = 40min
        XCTAssertEqual(auto, 40 * 60)
    }

    func testNetWorkTimeNegativeInputs() {
        let calc = BreakCalculator()
        let net = calc.netWorkTime(grossTime: -3600, manualPause: 0, idlePause: 0)
        // Should be clamped to 0
        XCTAssertEqual(net, 0)
    }

    // MARK: - Boundary Precision

    func testBreakAt6HoursMinusOneSecond() {
        let calc = BreakCalculator()
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 6 * 3600 - 1), 0)
    }

    func testBreakAt6HoursPlusOneSecond() {
        let calc = BreakCalculator()
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 6 * 3600 + 1), 30 * 60)
    }

    func testBreakAt9HoursMinusOneSecond() {
        let calc = BreakCalculator()
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 9 * 3600 - 1), 30 * 60)
    }

    func testBreakAt9HoursPlusOneSecond() {
        let calc = BreakCalculator()
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 9 * 3600 + 1), 45 * 60)
    }

    // MARK: - Very Long Work Days

    func testBreakFor12Hours() {
        let calc = BreakCalculator()
        // 12h is still in the >9h bracket → 45min
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 12 * 3600), 45 * 60)
    }

    func testBreakFor24Hours() {
        let calc = BreakCalculator()
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 24 * 3600), 45 * 60)
    }

    // MARK: - Custom Thresholds Validation

    func testZeroMinuteBreakThresholds() {
        let calc = BreakCalculator(breakAfter6hMinutes: 0, breakAfter9hMinutes: 0)
        // With 0 break minutes, no auto-break should be applied
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 7 * 3600), 0)
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 10 * 3600), 0)
    }

    func testLargeBreakThresholds() {
        let calc = BreakCalculator(breakAfter6hMinutes: 60, breakAfter9hMinutes: 90)
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 7 * 3600), 60 * 60)
        XCTAssertEqual(calc.requiredBreak(forWorkTime: 10 * 3600), 90 * 60)
    }

    // MARK: - Net Work Time Comprehensive

    func testNetWorkTimeOverall9hWithIdlePause() {
        let calc = BreakCalculator()
        // 10h gross, 30min manual, 15min idle
        // workBeforeAuto = 10h - 30min - 15min = 9h15min = 9.25h > 9h → 45min break
        // autoBreak = max(0, 45min - 45min) = 0 (already paused 45 total)
        // net = 9h15min - 0 = 9h15min
        let net = calc.netWorkTime(
            grossTime: 10 * 3600,
            manualPause: 30 * 60,
            idlePause: 15 * 60
        )
        XCTAssertEqual(net, 9 * 3600 + 15 * 60)
    }

    func testNetWorkTimeJustUnder6h() {
        let calc = BreakCalculator()
        // 5h59m gross, no pauses → no break needed
        let net = calc.netWorkTime(grossTime: 5 * 3600 + 59 * 60, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 5 * 3600 + 59 * 60)
    }

    func testNetWorkTimeExactly6h() {
        let calc = BreakCalculator()
        // 6h gross, no pauses → workBeforeAuto = 6h → NOT > 6h → no break
        let net = calc.netWorkTime(grossTime: 6 * 3600, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 6 * 3600)
    }

    func testNetWorkTimeJustOver6h() {
        let calc = BreakCalculator()
        // 6h01s gross, no pauses → workBeforeAuto = 6h01s → > 6h → 30min break
        // autoBreak = max(0, 30min - 0) = 30min
        // net = 6h01s - 30min = 5h30m01s
        let net = calc.netWorkTime(grossTime: 6 * 3600 + 1, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 5 * 3600 + 30 * 60 + 1)
    }

    // MARK: - Auto Break Partial Coverage

    func testAutoBreakPartialManualPause() {
        let calc = BreakCalculator()
        // 8h work, 20min already paused → required 30min, auto = 10min
        let auto = calc.autoBreak(forWorkTime: 8 * 3600, alreadyPaused: 20 * 60)
        XCTAssertEqual(auto, 10 * 60)
    }

    func testAutoBreakExactCoverage() {
        let calc = BreakCalculator()
        // 8h work, exactly 30min paused → auto = 0
        let auto = calc.autoBreak(forWorkTime: 8 * 3600, alreadyPaused: 30 * 60)
        XCTAssertEqual(auto, 0)
    }
}

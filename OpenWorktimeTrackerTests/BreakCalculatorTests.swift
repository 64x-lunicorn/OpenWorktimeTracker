import XCTest

@testable import OpenWorktimeTracker

final class BreakCalculatorTests: XCTestCase {

    private var calculator: BreakCalculator!

    override func setUp() {
        super.setUp()
        calculator = BreakCalculator(breakAfter6hMinutes: 30, breakAfter9hMinutes: 45)
    }

    // MARK: - Required Break

    func testNoBreakUnder6Hours() {
        // 5h 59m 59s — just under 6h
        let workTime: TimeInterval = 6 * 3600 - 1
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 0)
    }

    func testNoBreakExactly6Hours() {
        // Exactly 6h — NOT over 6h, so no break
        let workTime: TimeInterval = 6 * 3600
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 0)
    }

    func testBreak30MinAt6h01() {
        // 6h 1s — over 6h
        let workTime: TimeInterval = 6 * 3600 + 1
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 30 * 60)
    }

    func testBreak30MinAt7Hours() {
        let workTime: TimeInterval = 7 * 3600
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 30 * 60)
    }

    func testBreak30MinExactly9Hours() {
        // Exactly 9h — NOT over 9h, so still 30min
        let workTime: TimeInterval = 9 * 3600
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 30 * 60)
    }

    func testBreak45MinAt9h01() {
        // 9h 1s — over 9h
        let workTime: TimeInterval = 9 * 3600 + 1
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 45 * 60)
    }

    func testBreak45MinAt10Hours() {
        let workTime: TimeInterval = 10 * 3600
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: workTime), 45 * 60)
    }

    func testNoBreakForZeroTime() {
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: 0), 0)
    }

    // MARK: - Auto Break with Manual Pause

    func testAutoBreakReducedByManualPause() {
        // 7h work, 15 min already paused → auto break = 30 - 15 = 15 min
        let workTime: TimeInterval = 7 * 3600
        let manualPause: TimeInterval = 15 * 60
        XCTAssertEqual(
            calculator.autoBreak(forWorkTime: workTime, alreadyPaused: manualPause), 15 * 60)
    }

    func testAutoBreakZeroWhenManualPauseExceedsRequired() {
        // 7h work, 45 min already paused → auto break = max(0, 30 - 45) = 0
        let workTime: TimeInterval = 7 * 3600
        let manualPause: TimeInterval = 45 * 60
        XCTAssertEqual(calculator.autoBreak(forWorkTime: workTime, alreadyPaused: manualPause), 0)
    }

    func testAutoBreakZeroWhenManualPauseEqualsRequired() {
        // 7h work, 30 min already paused → auto break = 0
        let workTime: TimeInterval = 7 * 3600
        let manualPause: TimeInterval = 30 * 60
        XCTAssertEqual(calculator.autoBreak(forWorkTime: workTime, alreadyPaused: manualPause), 0)
    }

    // MARK: - Net Work Time

    func testNetWorkTimeUnder6Hours() {
        // 5h gross, no pauses → net = 5h
        let net = calculator.netWorkTime(grossTime: 5 * 3600, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 5 * 3600)
    }

    func testNetWorkTimeWith30MinAutoBreak() {
        // 8h gross, no manual pauses → work = 8h, auto break = 30min, net = 7h30
        let net = calculator.netWorkTime(grossTime: 8 * 3600, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 7 * 3600 + 30 * 60)
    }

    func testNetWorkTimeWithManualAndAutoBreak() {
        // 8h gross, 15min manual → work = 7h45, auto break = max(0, 30-15) = 15min, net = 7h30
        let net = calculator.netWorkTime(grossTime: 8 * 3600, manualPause: 15 * 60, idlePause: 0)
        XCTAssertEqual(net, 7 * 3600 + 30 * 60)
    }

    // MARK: - Custom Thresholds

    func testCustomBreakThresholds() {
        let custom = BreakCalculator(breakAfter6hMinutes: 20, breakAfter9hMinutes: 40)
        XCTAssertEqual(custom.requiredBreak(forWorkTime: 7 * 3600), 20 * 60)
        XCTAssertEqual(custom.requiredBreak(forWorkTime: 10 * 3600), 40 * 60)
    }

    // MARK: - Edge Cases

    func testAutoBreakWhenOverPaused() {
        // 7h work with 60min already paused → should be 0, not negative
        let auto = calculator.autoBreak(forWorkTime: 7 * 3600, alreadyPaused: 60 * 60)
        XCTAssertEqual(auto, 0)
    }

    func testNetWorkTimeNeverNegative() {
        // Very short work time with large pauses
        let net = calculator.netWorkTime(grossTime: 600, manualPause: 300, idlePause: 300)
        XCTAssertGreaterThanOrEqual(net, 0)
    }

    func testNetWorkTimeZeroGross() {
        let net = calculator.netWorkTime(grossTime: 0, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 0)
    }

    // MARK: - Negative Input Guards

    func testRequiredBreakNegativeWorkTime() {
        // Negative work time should return 0 (hours would be negative)
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: -3600), 0)
    }

    func testAutoBreakNegativeAlreadyPaused() {
        // Negative alreadyPaused is invalid but shouldn't crash
        // required = 30min, max(0, 30min - (-10min)) = 40min
        let auto = calculator.autoBreak(forWorkTime: 7 * 3600, alreadyPaused: -600)
        XCTAssertEqual(auto, 40 * 60)
    }

    func testNetWorkTimeNegativeInputs() {
        let net = calculator.netWorkTime(grossTime: -3600, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 0)
    }

    // MARK: - Very Long Work Days

    func testBreakFor12Hours() {
        // 12h is still in the >9h bracket → 45min
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: 12 * 3600), 45 * 60)
    }

    func testBreakFor24Hours() {
        XCTAssertEqual(calculator.requiredBreak(forWorkTime: 24 * 3600), 45 * 60)
    }

    // MARK: - Custom Threshold Validation

    func testZeroMinuteBreakThresholds() {
        let calc = BreakCalculator(breakAfter6hMinutes: 0, breakAfter9hMinutes: 0)
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
        // 10h gross, 30min manual, 15min idle → workBeforeAuto = 9h15m > 9h → 45min break;
        // already paused 45min → auto 0 → net = 9h15m
        let net = calculator.netWorkTime(
            grossTime: 10 * 3600, manualPause: 30 * 60, idlePause: 15 * 60)
        XCTAssertEqual(net, 9 * 3600 + 15 * 60)
    }

    func testNetWorkTimeJustUnder6h() {
        let net = calculator.netWorkTime(grossTime: 5 * 3600 + 59 * 60, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 5 * 3600 + 59 * 60)
    }

    func testNetWorkTimeExactly6h() {
        let net = calculator.netWorkTime(grossTime: 6 * 3600, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 6 * 3600)
    }

    func testNetWorkTimeJustOver6h() {
        // 6h01s → 30min break → net = 5h30m01s
        let net = calculator.netWorkTime(grossTime: 6 * 3600 + 1, manualPause: 0, idlePause: 0)
        XCTAssertEqual(net, 5 * 3600 + 30 * 60 + 1)
    }

    // MARK: - Auto Break Partial Coverage

    func testAutoBreakPartialManualPause() {
        // 8h work, 20min already paused → required 30min, auto = 10min
        let auto = calculator.autoBreak(forWorkTime: 8 * 3600, alreadyPaused: 20 * 60)
        XCTAssertEqual(auto, 10 * 60)
    }

    func testAutoBreakExactCoverage() {
        // 8h work, exactly 30min paused → auto = 0
        let auto = calculator.autoBreak(forWorkTime: 8 * 3600, alreadyPaused: 30 * 60)
        XCTAssertEqual(auto, 0)
    }
}

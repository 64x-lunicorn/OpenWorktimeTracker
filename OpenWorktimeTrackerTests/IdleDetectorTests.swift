import XCTest

@testable import OpenWorktimeTracker

final class IdleDetectorTests: XCTestCase {

    private var detector: IdleDetector!

    override func setUp() {
        super.setUp()
        detector = IdleDetector()
    }

    override func tearDown() {
        detector.stopMonitoring()
        detector = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertFalse(detector.isIdle)
        XCTAssertNil(detector.idleStartTime)
    }

    // MARK: - Stop Monitoring

    func testStopMonitoringResetsState() {
        detector.isIdle = true
        detector.idleStartTime = Date()

        detector.stopMonitoring()

        XCTAssertFalse(detector.isIdle)
        XCTAssertNil(detector.idleStartTime)
    }

    func testStartingMonitoringAgainPreservesInFlightIdlePeriod() {
        detector.startMonitoring()
        let start = Date().addingTimeInterval(-600)
        detector.isIdle = true
        detector.idleStartTime = start

        detector.startMonitoring()

        XCTAssertTrue(detector.isIdle)
        XCTAssertEqual(detector.idleStartTime, start)
    }

    func testIdlePeriodCannotStartBeforeMonitoringAndIsReportedOnce() {
        let clock = ManualClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        let start = clock.now
        var idleSeconds: TimeInterval = 7200
        detector = IdleDetector(clock: clock, idleTime: { idleSeconds })
        var periods: [IdlePeriod] = []
        detector.onPeriodEnded = { periods.append($0) }
        detector.startMonitoring()
        clock.now = clock.now.addingTimeInterval(600)
        detector.checkIdleState()
        idleSeconds = 0
        detector.checkIdleState()
        detector.checkIdleState()

        XCTAssertEqual(periods.count, 1)
        XCTAssertEqual(periods.first?.idleStart, start)
        XCTAssertEqual(periods.first?.duration, 600)
    }

    func testStoppingFromIdleCallbackDoesNotLeaveDetectorIdle() {
        let clock = ManualClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        var idleSeconds: TimeInterval = 600
        detector = IdleDetector(clock: clock, idleTime: { idleSeconds })
        detector.startMonitoring()
        clock.now = clock.now.addingTimeInterval(600)
        detector.checkIdleState()
        detector.onPeriodEnded = { [weak detector] _ in detector?.stopMonitoring() }
        idleSeconds = 0

        detector.checkIdleState()

        XCTAssertFalse(detector.isIdle)
        XCTAssertNil(detector.idleStartTime)
    }

    // MARK: - Callback

    func testOnPeriodEndedCallbackIsSet() {
        var callbackCalled = false
        detector.onPeriodEnded = { _ in
            callbackCalled = true
        }

        XCTAssertNotNil(detector.onPeriodEnded)
        let period = IdlePeriod(
            idleStart: Date().addingTimeInterval(-600),
            idleEnd: Date(),
            spansMidnight: false
        )
        detector.onPeriodEnded?(period)
        XCTAssertTrue(callbackCalled)
    }

    // MARK: - IdlePeriod

    func testIdlePeriodDuration() {
        let start = Date().addingTimeInterval(-300)
        let end = Date()
        let period = IdlePeriod(idleStart: start, idleEnd: end, spansMidnight: false)
        XCTAssertEqual(period.duration, end.timeIntervalSince(start), accuracy: 0.01)
    }

    func testIdlePeriodSpansMidnight() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let period = IdlePeriod(idleStart: yesterday, idleEnd: Date(), spansMidnight: true)
        XCTAssertTrue(period.spansMidnight)
    }

    func testIdlePeriodDoesNotSpanMidnight() {
        let period = IdlePeriod(
            idleStart: Date().addingTimeInterval(-600), idleEnd: Date(), spansMidnight: false)
        XCTAssertFalse(period.spansMidnight)
    }

    func testIdlePeriodHasUniqueID() {
        let period1 = IdlePeriod(idleStart: Date(), idleEnd: Date(), spansMidnight: false)
        let period2 = IdlePeriod(idleStart: Date(), idleEnd: Date(), spansMidnight: false)
        XCTAssertNotEqual(period1.id, period2.id)
    }

    // MARK: - Idle Threshold

    func testIdleThresholdDefaultsToAPositiveValue() {
        XCTAssertGreaterThan(detector.idleThreshold.seconds, 0)
    }

    func testIdleThresholdSecondsConvertsMinutes() {
        XCTAssertEqual(IdleThreshold(minutes: 3).seconds, 180)
    }

    func testIdleThresholdGuaranteesPositivityForAZeroOverride() {
        XCTAssertEqual(IdleThreshold(minutes: 0).minutes, AppDefaults.idleThresholdMinutes)
    }

    func testIdleThresholdGuaranteesPositivityForANegativeOverride() {
        XCTAssertEqual(IdleThreshold(minutes: -5).minutes, AppDefaults.idleThresholdMinutes)
    }

    func testIdleThresholdKeepsAPositiveOverride() {
        XCTAssertEqual(IdleThreshold(minutes: 10).minutes, 10)
    }

    func testIdleThresholdResolvedFromInjectedDefaults() {
        let suiteName = "idle-detector-tests-\(UUID())"
        let suite = UserDefaults(suiteName: suiteName)!
        addTeardownBlock { suite.removePersistentDomain(forName: suiteName) }
        suite.set(15, forKey: AppSettingsKey.idleThresholdMinutes)

        XCTAssertEqual(IdleThreshold.resolved(from: suite).minutes, 15)
    }
}

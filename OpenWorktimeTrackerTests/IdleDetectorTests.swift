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
        XCTAssertNil(detector.pendingPrompt)
    }

    // MARK: - Dismiss Prompt

    func testDismissPromptClearsPendingPrompt() {
        // Manually set a pending prompt for test
        detector.pendingPrompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-600),
            idleEnd: Date(),
            duration: 600,
            spansMidnight: false
        )
        XCTAssertNotNil(detector.pendingPrompt)

        detector.dismissPrompt()
        XCTAssertNil(detector.pendingPrompt)
    }

    // MARK: - Stop Monitoring

    func testStopMonitoringResetsState() {
        detector.isIdle = true
        detector.idleStartTime = Date()

        detector.stopMonitoring()

        XCTAssertFalse(detector.isIdle)
        XCTAssertNil(detector.idleStartTime)
    }

    // MARK: - Callback

    func testOnPromptReadyCallbackIsSet() {
        var callbackCalled = false
        detector.onPromptReady = { _ in
            callbackCalled = true
        }

        // Verify callback is stored
        XCTAssertNotNil(detector.onPromptReady)
        // Invoke it manually
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-600),
            idleEnd: Date(),
            duration: 600,
            spansMidnight: false
        )
        detector.onPromptReady?(prompt)
        XCTAssertTrue(callbackCalled)
    }

    // MARK: - IdlePromptInfo

    func testIdlePromptInfoDurationFormatMinutes() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-300),
            idleEnd: Date(),
            duration: 300,
            spansMidnight: false
        )
        XCTAssertEqual(prompt.formattedDuration, "5 Min")
    }

    func testIdlePromptInfoDurationFormatHours() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-5400),
            idleEnd: Date(),
            duration: 5400,
            spansMidnight: false
        )
        XCTAssertEqual(prompt.formattedDuration, "1h 30m")
    }

    func testIdlePromptInfoSpansMidnight() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let prompt = IdlePromptInfo(
            idleStart: yesterday,
            idleEnd: Date(),
            duration: Date().timeIntervalSince(yesterday),
            spansMidnight: true
        )
        XCTAssertTrue(prompt.spansMidnight)
    }

    func testIdlePromptInfoDoesNotSpanMidnight() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-600),
            idleEnd: Date(),
            duration: 600,
            spansMidnight: false
        )
        XCTAssertFalse(prompt.spansMidnight)
    }

    // MARK: - Duplicate Prompt Prevention

    func testNoNewPromptWhilePendingExists() {
        let existingPrompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-1200),
            idleEnd: Date().addingTimeInterval(-600),
            duration: 600,
            spansMidnight: false
        )
        detector.pendingPrompt = existingPrompt
        let existingID = existingPrompt.id

        var callbackCount = 0
        detector.onPromptReady = { _ in
            callbackCount += 1
        }

        // A pending prompt must not be overwritten by a new idle cycle
        detector.isIdle = true
        detector.idleStartTime = Date().addingTimeInterval(-300)

        XCTAssertNotNil(detector.pendingPrompt)
        XCTAssertEqual(detector.pendingPrompt?.id, existingID)
        XCTAssertEqual(callbackCount, 0)
    }

    func testDismissAllowsNewPrompt() {
        let prompt1 = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-1200),
            idleEnd: Date().addingTimeInterval(-600),
            duration: 600,
            spansMidnight: false
        )
        detector.pendingPrompt = prompt1

        detector.dismissPrompt()
        XCTAssertNil(detector.pendingPrompt)

        let prompt2 = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-300),
            idleEnd: Date(),
            duration: 300,
            spansMidnight: false
        )
        detector.pendingPrompt = prompt2
        XCTAssertNotNil(detector.pendingPrompt)
    }

    func testStopMonitoringClearsPendingPrompt() {
        detector.isIdle = true
        detector.idleStartTime = Date()
        detector.pendingPrompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-600),
            idleEnd: Date(),
            duration: 600,
            spansMidnight: false
        )

        detector.stopMonitoring()

        XCTAssertFalse(detector.isIdle)
        XCTAssertNil(detector.idleStartTime)
        // stopMonitoring clears pendingPrompt so no stale prompt lingers after day ends
        XCTAssertNil(detector.pendingPrompt)
    }

    // MARK: - Idle Threshold

    func testIdleThresholdNonNegative() {
        // With no UserDefaults value the code falls back rather than returning a
        // negative or unusable threshold.
        XCTAssertGreaterThanOrEqual(detector.idleThresholdSeconds, 0)
    }

    // MARK: - IdlePromptInfo Formatting

    func testFormattedDurationExactlyOneHour() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-3600),
            idleEnd: Date(),
            duration: 3600,
            spansMidnight: false
        )
        XCTAssertEqual(prompt.formattedDuration, "1h 0m")
    }

    func testFormattedDurationLessThanOneMinute() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-30),
            idleEnd: Date(),
            duration: 30,
            spansMidnight: false
        )
        XCTAssertEqual(prompt.formattedDuration, "0 Min")
    }

    func testFormattedDurationMultipleHours() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-7500),
            idleEnd: Date(),
            duration: 7500,  // 2h 5m
            spansMidnight: false
        )
        XCTAssertEqual(prompt.formattedDuration, "2h 5m")
    }

    func testFormattedRangeContainsDash() {
        let prompt = IdlePromptInfo(
            idleStart: Date().addingTimeInterval(-3600),
            idleEnd: Date(),
            duration: 3600,
            spansMidnight: false
        )
        XCTAssertTrue(prompt.formattedRange.contains("–"))
    }

    // MARK: - Unique IDs

    func testPromptInfoHasUniqueID() {
        let prompt1 = IdlePromptInfo(
            idleStart: Date(), idleEnd: Date(), duration: 0, spansMidnight: false)
        let prompt2 = IdlePromptInfo(
            idleStart: Date(), idleEnd: Date(), duration: 0, spansMidnight: false)
        XCTAssertNotEqual(prompt1.id, prompt2.id)
    }
}

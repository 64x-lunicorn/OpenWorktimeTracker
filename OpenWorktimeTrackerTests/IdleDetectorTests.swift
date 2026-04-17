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
}

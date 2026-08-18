import CoreGraphics
import Foundation

@Observable
final class IdleDetector {

    // MARK: - State

    var isIdle = false
    var idleStartTime: Date?

    /// De-dup guard, internal to detection: prevents a still-undecided Idle
    /// Period from being reported twice. Not the source of truth for whether a
    /// decision is pending — WorkdayManager owns that.
    private var pendingPeriod: IdlePeriod?

    private var screenLocked = false
    private var lockTime: Date?
    private var isMonitoring = false
    private var observersRegistered = false

    /// Called once when an Idle Period ends and needs a decision.
    var onPeriodEnded: ((IdlePeriod) -> Void)?

    // MARK: - Configuration

    var idleThreshold: IdleThreshold = .resolved()

    private var checkTimer: Timer?

    // MARK: - Lifecycle

    func startMonitoring() {
        // Restart only the polling timer; the lock/unlock observers stay alive
        // for the object's lifetime so an in-flight unlock handler is never torn
        // down mid-execution (e.g. when a new day starts during unlock).
        checkTimer?.invalidate()
        isMonitoring = true
        isIdle = false
        idleStartTime = nil
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
        registerScreenLockObservers()
    }

    func stopMonitoring() {
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
        isIdle = false
        idleStartTime = nil
        pendingPeriod = nil
    }

    /// Tells the detector the Idle Period it last reported has been decided,
    /// so a new one can be reported when the next idle stretch ends.
    func periodResolved() {
        pendingPeriod = nil
    }

    // MARK: - Screen Lock/Unlock

    private func registerScreenLockObservers() {
        guard !observersRegistered else { return }
        observersRegistered = true
        let dnc = DistributedNotificationCenter.default()

        dnc.addObserver(
            self,
            selector: #selector(screenDidLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        dnc.addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func screenDidLock() {
        guard isMonitoring else { return }
        screenLocked = true
        lockTime = Date()
        // Stop timer polling — lock/unlock handlers take over
        checkTimer?.invalidate()
        checkTimer = nil
        // Treat screen lock as start of idle
        if !isIdle {
            isIdle = true
            idleStartTime = Date()
        }
    }

    @objc private func screenDidUnlock() {
        guard isMonitoring, screenLocked else { return }
        screenLocked = false
        let unlockTime = Date()

        if pendingPeriod == nil, let start = idleStartTime ?? lockTime {
            let duration = unlockTime.timeIntervalSince(start)

            if duration >= idleThreshold.seconds {
                let period = IdlePeriod(
                    idleStart: start,
                    idleEnd: unlockTime,
                    spansMidnight: !Calendar.current.isDate(start, inSameDayAs: unlockTime)
                )
                pendingPeriod = period
                onPeriodEnded?(period)
            }
        }
        isIdle = false
        idleStartTime = nil
        lockTime = nil

        // Restart timer polling after unlock
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    // MARK: - Idle Check

    private func checkIdleState() {
        // Skip polling when screen is locked — handled by lock/unlock observers
        guard !screenLocked else { return }

        let idleSeconds = currentIdleTime()

        if idleSeconds >= idleThreshold.seconds {
            // User is idle
            if !isIdle {
                isIdle = true
                idleStartTime = Date().addingTimeInterval(-idleSeconds)
            }
        } else if isIdle {
            // User returned from idle
            let returnTime = Date()
            if pendingPeriod == nil, let start = idleStartTime {
                let period = IdlePeriod(
                    idleStart: start,
                    idleEnd: returnTime,
                    spansMidnight: !Calendar.current.isDate(start, inSameDayAs: returnTime)
                )
                pendingPeriod = period
                onPeriodEnded?(period)
            }
            isIdle = false
            idleStartTime = nil
        }
    }

    private func currentIdleTime() -> TimeInterval {
        // Check both mouse and keyboard events, return the smaller value
        // (= time since last activity of any kind)
        let mouseMoved = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .mouseMoved)
        let mouseDown = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .leftMouseDown)
        let keyDown = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .keyDown)
        return min(mouseMoved, mouseDown, keyDown)
    }
}

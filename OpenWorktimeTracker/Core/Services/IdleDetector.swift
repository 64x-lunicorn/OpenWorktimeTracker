import CoreGraphics
import Foundation

@Observable
final class IdleDetector {

    enum ActivityEvent {
        case sleep, wake, lock, unlock
    }

    // MARK: - State

    var isIdle = false
    var idleStartTime: Date?

    /// De-dup guard, internal to detection: prevents a still-undecided Idle
    /// Period from being reported twice. Not the source of truth for whether a
    /// decision is pending — WorkdayManager owns that.
    private var pendingPeriod: IdlePeriod?

    private var screenLocked = false
    private var sleeping = false
    private var lockTime: Date?
    private var isMonitoring = false

    /// Called once when an Idle Period ends and needs a decision.
    var onPeriodEnded: ((IdlePeriod) -> Void)?

    // MARK: - Configuration

    var idleThreshold: IdleThreshold = .resolved()

    private var checkTimer: Timer?
    private let clock: Clock
    private let idleTime: () -> TimeInterval
    private var monitoringStartedAt: Date?

    init(clock: Clock = SystemClock(), idleTime: @escaping () -> TimeInterval = IdleDetector.systemIdleTime) {
        self.clock = clock
        self.idleTime = idleTime
    }

    var isSuspended: Bool { screenLocked || sleeping }
    var hasRecentActivity: Bool { !isSuspended && idleTime() < idleThreshold.seconds }
    var lastActivityTime: Date { clock.now.addingTimeInterval(-idleTime()) }

    // MARK: - Lifecycle

    func startMonitoring() {
        guard !isMonitoring else { return }
        // Repeated wake/evaluation events must not erase an ongoing idle period.
        checkTimer?.invalidate()
        isMonitoring = true
        monitoringStartedAt = clock.now
        isIdle = false
        idleStartTime = nil
        if isSuspended {
            beginSuspension()
        } else {
            startPolling()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
        isIdle = false
        idleStartTime = nil
        pendingPeriod = nil
        lockTime = nil
        monitoringStartedAt = nil
    }

    /// Tells the detector the Idle Period it last reported has been decided,
    /// so a new one can be reported when the next idle stretch ends.
    func periodResolved() {
        pendingPeriod = nil
    }

    // MARK: - Ordered activity events

    func handle(_ event: ActivityEvent) {
        let wasSuspended = isSuspended
        switch event {
        case .sleep: sleeping = true
        case .wake: sleeping = false
        case .lock: screenLocked = true
        case .unlock: screenLocked = false
        }
        guard isMonitoring else { return }
        if !wasSuspended && isSuspended {
            beginSuspension()
        } else if wasSuspended && !isSuspended {
            endSuspension()
        }
    }

    deinit {
        checkTimer?.invalidate()
    }

    private func beginSuspension() {
        lockTime = clock.now
        // Stop timer polling — lock/unlock handlers take over
        checkTimer?.invalidate()
        checkTimer = nil
        // Treat screen lock as start of idle
        if !isIdle {
            isIdle = true
            idleStartTime = clock.now
        }
    }

    private func endSuspension() {
        let unlockTime = clock.now
        let start = idleStartTime ?? lockTime
        isIdle = false
        idleStartTime = nil
        lockTime = nil

        if pendingPeriod == nil, let start {
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
        if isMonitoring && !isSuspended {
            startPolling()
        }
    }

    private func startPolling() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    // MARK: - Idle Check

    func checkIdleState() {
        // Skip polling when screen is locked — handled by lock/unlock observers
        guard isMonitoring, !isSuspended else { return }

        let idleSeconds = idleTime()

        if idleSeconds >= idleThreshold.seconds {
            // User is idle
            if !isIdle {
                isIdle = true
                idleStartTime = max(
                    monitoringStartedAt ?? clock.now, clock.now.addingTimeInterval(-idleSeconds))
            }
        } else if isIdle {
            // User returned from idle
            let returnTime = clock.now
            let start = idleStartTime
            isIdle = false
            idleStartTime = nil
            if pendingPeriod == nil, let start {
                let period = IdlePeriod(
                    idleStart: start,
                    idleEnd: returnTime,
                    spansMidnight: !Calendar.current.isDate(start, inSameDayAs: returnTime)
                )
                pendingPeriod = period
                onPeriodEnded?(period)
            }
        }
    }

    static func systemIdleTime() -> TimeInterval {
        // kCGAnyInputEventType is the all-events sentinel, not a Swift enum case.
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: CGEventType(rawValue: UInt32.max)!)
    }
}

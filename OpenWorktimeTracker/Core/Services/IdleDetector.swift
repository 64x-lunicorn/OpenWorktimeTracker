import CoreGraphics
import Foundation

@Observable
final class IdleDetector {

    // MARK: - State

    var isIdle = false
    var idleStartTime: Date?
    var pendingPrompt: IdlePromptInfo?
    private var screenLocked = false
    private var lockTime: Date?

    /// Called when a new idle prompt should be shown.
    var onPromptReady: ((IdlePromptInfo) -> Void)?

    // MARK: - Configuration

    var idleThresholdSeconds: TimeInterval {
        Double(UserDefaults.standard.integer(forKey: AppSettingsKey.idleThresholdMinutes)) * 60.0
    }

    private var checkTimer: Timer?

    // MARK: - Lifecycle

    func startMonitoring() {
        stopMonitoring()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
        registerScreenLockObservers()
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        isIdle = false
        idleStartTime = nil
        DistributedNotificationCenter.default().removeObserver(self)
    }

    // MARK: - Screen Lock/Unlock

    private func registerScreenLockObservers() {
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

    @objc private func screenDidLock() {
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
        guard screenLocked else { return }
        screenLocked = false
        let unlockTime = Date()

        if pendingPrompt == nil, let start = idleStartTime ?? lockTime {
            let duration = unlockTime.timeIntervalSince(start)
            let threshold = idleThresholdSeconds > 0 ? idleThresholdSeconds : 300

            if duration >= threshold {
                let spansMidnight = !Calendar.current.isDate(start, inSameDayAs: unlockTime)
                pendingPrompt = IdlePromptInfo(
                    idleStart: start,
                    idleEnd: unlockTime,
                    duration: duration,
                    spansMidnight: spansMidnight
                )
                if let prompt = pendingPrompt {
                    onPromptReady?(prompt)
                }
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
        let threshold = idleThresholdSeconds > 0 ? idleThresholdSeconds : 300  // default 5 min

        if idleSeconds >= threshold {
            // User is idle
            if !isIdle {
                isIdle = true
                idleStartTime = Date().addingTimeInterval(-idleSeconds)
            }
        } else if isIdle {
            // User returned from idle
            let returnTime = Date()
            if pendingPrompt == nil, let start = idleStartTime {
                let duration = returnTime.timeIntervalSince(start)
                let spansMidnight = !Calendar.current.isDate(start, inSameDayAs: returnTime)

                pendingPrompt = IdlePromptInfo(
                    idleStart: start,
                    idleEnd: returnTime,
                    duration: duration,
                    spansMidnight: spansMidnight
                )
                if let prompt = pendingPrompt {
                    onPromptReady?(prompt)
                }
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

    func dismissPrompt() {
        pendingPrompt = nil
    }
}

// MARK: - Prompt Info

struct IdlePromptInfo: Identifiable {
    let id = UUID()
    let idleStart: Date
    let idleEnd: Date
    let duration: TimeInterval
    let spansMidnight: Bool

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) Min"
    }

    var formattedRange: String {
        "\(idleStart.hoursMinutesString) – \(idleEnd.hoursMinutesString)"
    }
}

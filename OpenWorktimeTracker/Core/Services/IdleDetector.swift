import CoreGraphics
import Foundation

@Observable
final class IdleDetector {

    // MARK: - State

    var isIdle = false
    var idleStartTime: Date?
    var pendingPrompt: IdlePromptInfo?

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
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        isIdle = false
        idleStartTime = nil
    }

    // MARK: - Idle Check

    private func checkIdleState() {
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
            if let start = idleStartTime {
                let duration = returnTime.timeIntervalSince(start)
                let spansMidnight = !Calendar.current.isDate(start, inSameDayAs: returnTime)

                pendingPrompt = IdlePromptInfo(
                    idleStart: start,
                    idleEnd: returnTime,
                    duration: duration,
                    spansMidnight: spansMidnight
                )
            }
            isIdle = false
            idleStartTime = nil
        }
    }

    private func currentIdleTime() -> TimeInterval {
        // CGEventSource.secondsSinceLastEventType gives seconds since last HID event
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
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

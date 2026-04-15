import Foundation

struct TimeEntry: Codable, Identifiable {
    let id: UUID
    var date: String  // YYYY-MM-DD
    var startTime: Date
    var endTime: Date?
    var status: Status
    var manualPauseSeconds: TimeInterval
    var pauseStartedAt: Date?
    var idleDecisions: [IdleDecision]
    var notifiedThresholds: Set<String>
    var note: String

    enum Status: String, Codable {
        case running
        case paused
        case ended
    }

    init(
        id: UUID = UUID(),
        date: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        status: Status = .running,
        manualPauseSeconds: TimeInterval = 0,
        pauseStartedAt: Date? = nil,
        idleDecisions: [IdleDecision] = [],
        notifiedThresholds: Set<String> = [],
        note: String = ""
    ) {
        self.id = id
        self.date = date ?? Self.dateString(from: startTime)
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.manualPauseSeconds = manualPauseSeconds
        self.pauseStartedAt = pauseStartedAt
        self.idleDecisions = idleDecisions
        self.notifiedThresholds = notifiedThresholds
        self.note = note
    }

    // MARK: - Computed Properties

    var grossTime: TimeInterval {
        let end = endTime ?? Date()
        return max(0, end.timeIntervalSince(startTime))
    }

    var totalManualPause: TimeInterval {
        var pause = manualPauseSeconds
        if status == .paused, let pauseStart = pauseStartedAt {
            pause += Date().timeIntervalSince(pauseStart)
        }
        return pause
    }

    var totalIdlePause: TimeInterval {
        idleDecisions
            .filter { $0.decision == .pause }
            .reduce(0) { $0 + $1.duration }
    }

    var totalPause: TimeInterval {
        totalManualPause + totalIdlePause
    }

    var workTimeBeforeAutoBreak: TimeInterval {
        max(0, grossTime - totalPause)
    }

    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

struct IdleDecision: Codable, Identifiable {
    let id: UUID
    let idleStart: Date
    let idleEnd: Date
    let decision: Decision

    enum Decision: String, Codable {
        case work  // Count as work time (meeting, thinking)
        case pause  // Deduct from work time
    }

    var duration: TimeInterval {
        idleEnd.timeIntervalSince(idleStart)
    }

    init(id: UUID = UUID(), idleStart: Date, idleEnd: Date, decision: Decision) {
        self.id = id
        self.idleStart = idleStart
        self.idleEnd = idleEnd
        self.decision = decision
    }
}

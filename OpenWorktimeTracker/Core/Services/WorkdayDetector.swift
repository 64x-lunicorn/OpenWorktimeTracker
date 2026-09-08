import Foundation

struct WorkdayDetector {

    enum Action {
        /// Continue tracking an existing entry for today
        case continueExisting(TimeEntry)
        /// Start a brand-new workday (no entry today, no stale running entry)
        case startFreshDay
        /// A previous day's entry is still running and must be closed before starting today
        case endPreviousAndStartNew(previous: TimeEntry, suggestedEndTime: Date)
        /// Today's entry was already ended (day is done)
        case dayAlreadyEnded(TimeEntry)
    }

    private let newDayStartHour: Int
    private let calendar = Calendar.current

    init(newDayStartHour: Int = AppDefaults.newDayStartHour) {
        self.newDayStartHour = (0...23).contains(newDayStartHour) ? newDayStartHour : AppDefaults.newDayStartHour
    }

    /// Determines what action should be taken on app launch or wake.
    func evaluate(todayEntry: TimeEntry?, mostRecentEntry: TimeEntry?, now: Date = Date()) -> Action {
        let effectiveDay = effectiveDateString(for: now)

        // Check if there's an entry matching today's effective date
        if let today = [todayEntry, mostRecentEntry].compactMap({ $0 })
            .first(where: { $0.date == effectiveDay }) {
            switch today.status {
            case .running, .paused:
                return .continueExisting(today)
            case .ended:
                return .dayAlreadyEnded(today)
            }
        }

        // Check the most recent entry from any day
        if let recent = mostRecentEntry, recent.date < effectiveDay {
            switch recent.status {
            case .running, .paused:
                // Still running from a previous day — need to end it
                let suggestedEnd = suggestEndTime(for: recent)
                return .endPreviousAndStartNew(previous: recent, suggestedEndTime: suggestedEnd)
            case .ended:
                // Previous day properly ended, start fresh
                return .startFreshDay
            }
        }

        // No entries at all — first run
        return .startFreshDay
    }

    /// Determines the "effective" date string.
    /// Before `newDayStartHour` (e.g., 4 AM), we consider it still the previous day.
    func effectiveDateString(for date: Date) -> String {
        let hour = calendar.component(.hour, from: date)
        if hour < newDayStartHour {
            // Before 4 AM → still counts as "yesterday"
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
                return TimeEntry.dateString(from: date)
            }

            return TimeEntry.dateString(from: yesterday)
        }
        return TimeEntry.dateString(from: date)
    }

    func startOfEffectiveDay(for date: Date) -> Date {
        let midnight = calendar.startOfDay(for: date)
        let boundary = calendar.date(bySettingHour: newDayStartHour, minute: 0, second: 0, of: midnight)!
        if date < boundary {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: midnight)!
            return calendar.date(bySettingHour: newDayStartHour, minute: 0, second: 0, of: yesterday)!
        }
        return boundary
    }

    /// Suggests when the previous day's entry should end.
    /// Uses the last idle decision's end time or a reasonable estimate.
    private func suggestEndTime(for entry: TimeEntry) -> Date {
        if let pauseStart = entry.pauseStartedAt, entry.status == .paused {
            return max(entry.startTime, pauseStart)
        }
        if let lastActivity = entry.lastActivityTime {
            return max(entry.startTime, lastActivity)
        }
        // If there are idle decisions, use the start of the last big idle as the end
        if let lastIdle = entry.idleDecisions.last, lastIdle.decision == .pause {
            return max(entry.startTime, lastIdle.idleStart)
        }

        // Default: end of the day the entry was created (18:00 or start time, whichever is later)
        var components = calendar.dateComponents([.year, .month, .day], from: entry.startTime)
        components.hour = 18  // Default fallback: 6 PM
        components.minute = 0
        if let fallback = calendar.date(from: components) {
            // Ensure suggested end is not before start time
            return max(fallback, entry.startTime, entry.idleDecisions.last?.idleEnd ?? entry.startTime)
        }
        return entry.startTime
    }
}

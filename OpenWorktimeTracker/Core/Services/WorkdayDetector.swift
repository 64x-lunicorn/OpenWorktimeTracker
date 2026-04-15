import Foundation

struct WorkdayDetector {

    enum Action {
        /// Continue tracking an existing entry for today
        case continueExisting(TimeEntry)
        /// Start a brand-new workday (no entry today, no stale running entry)
        case startFreshDay
        /// A previous day's entry is still running — needs user confirmation to end it
        case endPreviousAndStartNew(previous: TimeEntry, suggestedEndTime: Date)
        /// Today's entry was already ended (day is done)
        case dayAlreadyEnded(TimeEntry)
    }

    private let newDayStartHour: Int
    private let calendar = Calendar.current

    init(newDayStartHour: Int = AppDefaults.newDayStartHour) {
        self.newDayStartHour = newDayStartHour
    }

    /// Determines what action should be taken on app launch or wake.
    func evaluate(todayEntry: TimeEntry?, mostRecentEntry: TimeEntry?) -> Action {
        let now = Date()
        let effectiveDay = effectiveDateString(for: now)

        // Check if there's an entry matching today's effective date
        if let today = todayEntry, today.date == effectiveDay {
            switch today.status {
            case .running, .paused:
                return .continueExisting(today)
            case .ended:
                return .dayAlreadyEnded(today)
            }
        }

        // Check the most recent entry from any day
        if let recent = mostRecentEntry {
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
            let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
            return TimeEntry.dateString(from: yesterday)
        }
        return TimeEntry.dateString(from: date)
    }

    /// Suggests when the previous day's entry should end.
    /// Uses the last idle decision's end time or a reasonable estimate.
    private func suggestEndTime(for entry: TimeEntry) -> Date {
        // If there are idle decisions, use the start of the last big idle as the end
        if let lastIdle = entry.idleDecisions.last {
            return lastIdle.idleStart
        }

        // Default: end of the day the entry was created (23:59 or last known activity)
        var components = calendar.dateComponents([.year, .month, .day], from: entry.startTime)
        components.hour = 18  // Default fallback: 6 PM
        components.minute = 0
        return calendar.date(from: components) ?? entry.startTime
    }
}

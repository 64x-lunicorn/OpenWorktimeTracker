import Foundation

@testable import OpenWorktimeTracker

/// Test double for `DailyLogStore`. Holds Daily Logs in memory, so
/// `WorkdayManager` tests never touch the filesystem.
final class InMemoryDailyLogStore: DailyLogStore {

    private var entriesByDate: [String: TimeEntry] = [:]
    private(set) var syncWithCloudCallCount = 0

    func loadToday() -> TimeEntry? {
        load(for: TimeEntry.dateString(from: Date()))
    }

    func loadMostRecentEntry() -> TimeEntry? {
        entriesByDate.values.max { $0.date < $1.date }
    }

    func load(for dateString: String) -> TimeEntry? {
        entriesByDate[dateString]
    }

    func save(_ entry: TimeEntry) {
        entriesByDate[entry.date] = entry
    }

    func syncWithCloud() {
        syncWithCloudCallCount += 1
    }

    func exportCSV(workdayFor makeWorkday: (TimeEntry) -> Workday) -> URL? {
        nil
    }
}

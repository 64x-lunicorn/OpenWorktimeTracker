import Foundation

@testable import OpenWorktimeTracker

/// Test double for `DailyLogStore`. Holds Daily Logs in memory, so
/// `WorkdayManager` tests never touch the filesystem.
final class InMemoryDailyLogStore: DailyLogStore {

    private var entriesByDate: [String: TimeEntry] = [:]
    private(set) var syncWithCloudCallCount = 0
    var saveSucceeds = true
    var deleteSucceeds = true
    private(set) var flushCallCount = 0

    func loadToday() -> TimeEntry? {
        load(for: TimeEntry.dateString(from: Date()))
    }

    func loadMostRecentEntry() -> TimeEntry? {
        entriesByDate.values.max { $0.date < $1.date }
    }

    func load(for dateString: String) -> TimeEntry? {
        entriesByDate[dateString]
    }

    func loadAll() -> [TimeEntry] {
        entriesByDate.values.sorted { $0.date > $1.date }
    }

    func save(_ entry: TimeEntry) {
        entriesByDate[entry.date] = entry
    }

    func saveAndWait(_ entry: TimeEntry) -> Bool {
        guard saveSucceeds else { return false }
        save(entry)
        return true
    }

    @discardableResult
    func delete(for date: String) -> Bool {
        guard deleteSucceeds else { return false }
        entriesByDate.removeValue(forKey: date)
        return true
    }

    func flush() {
        flushCallCount += 1
    }

    func syncWithCloud() {
        syncWithCloudCallCount += 1
    }

    func exportCSV(workdayFor makeWorkday: (TimeEntry) -> Workday) -> URL? {
        nil
    }
}

import Foundation

/// Where Daily Logs are read and written. `WorkdayManager` depends on this
/// for its own load/save logic, so tests can supply an in-memory adapter
/// instead of touching the filesystem — see ADR-0001.
///
/// `PersistenceManager` is the production adapter. `WorkdayManager` also
/// keeps a directly-typed `persistence: PersistenceManager` alongside this,
/// since several views reach the concrete type directly (log export,
/// browsing the log folder, iCloud sync) — that surface is out of scope
/// here and belongs to a future Daily Log query interface.
protocol DailyLogStore {
    func loadToday() -> TimeEntry?
    func loadMostRecentEntry() -> TimeEntry?
    func load(for dateString: String) -> TimeEntry?
    func save(_ entry: TimeEntry)
    func syncWithCloud()
    func exportCSV(workdayFor makeWorkday: (TimeEntry) -> Workday) -> URL?
}

extension PersistenceManager: DailyLogStore {}

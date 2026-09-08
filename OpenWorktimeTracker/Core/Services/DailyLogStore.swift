import Foundation

/// Where Daily Logs are read and written. `WorkdayManager` depends on this
/// for Daily Log mutations and queries, so tests can supply an in-memory adapter
/// instead of touching the filesystem — see ADR-0001.
///
/// `PersistenceManager` is the production adapter. `WorkdayManager` also
/// keeps a directly-typed `persistence: PersistenceManager` alongside this,
/// for filesystem settings and folder navigation, not editor mutations.
protocol DailyLogStore {
    func loadToday() -> TimeEntry?
    func loadMostRecentEntry() -> TimeEntry?
    func load(for dateString: String) -> TimeEntry?
    func loadAll() -> [TimeEntry]
    func save(_ entry: TimeEntry)
    /// Confirms the local write before an editor reports success.
    func saveAndWait(_ entry: TimeEntry) -> Bool
    func delete(for dateString: String) -> Bool
    func flush()
    func syncWithCloud()
    func exportCSV(workdayFor makeWorkday: (TimeEntry) -> Workday) -> URL?
}

extension PersistenceManager: DailyLogStore {}

enum DailyLogMutationError: LocalizedError {
    case missingEntry
    case invalidTimes
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .missingEntry: return String(localized: "logEditor.error.missingEntry")
        case .invalidTimes: return String(localized: "logEditor.error.invalidTimes")
        case .saveFailed: return String(localized: "logEditor.error.saveFailed")
        case .deleteFailed: return String(localized: "logEditor.error.deleteFailed")
        }
    }
}

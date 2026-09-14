import Foundation

/// Where the tracked Workday stands, shared with the widget through its snapshot.
///
/// Raw values are part of the published snapshot and must not change.
enum WorkdayState: String, Codable, CaseIterable {
    case notStarted
    case running
    case paused
    case ended
}

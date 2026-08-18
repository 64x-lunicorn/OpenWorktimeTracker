import Foundation

@testable import OpenWorktimeTracker

/// Test double for `Clock`. Lets tests drive WorkdayManager's time-dependent
/// logic with an exact instant instead of asserting against real wall-clock
/// time with a tolerance.
final class ManualClock: Clock {
    var now: Date

    init(now: Date = Date(timeIntervalSince1970: 0)) {
        self.now = now
    }
}

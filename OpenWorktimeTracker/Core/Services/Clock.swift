import Foundation

/// The current moment. `WorkdayManager` depends on this instead of calling
/// `Date()` directly, so its time-dependent logic can be tested
/// deterministically.
///
/// `Workday` itself stays clock-free — see ADR-0001.
protocol Clock {
    var now: Date { get }
}

/// The production adapter: wall-clock time.
struct SystemClock: Clock {
    var now: Date { Date() }
}

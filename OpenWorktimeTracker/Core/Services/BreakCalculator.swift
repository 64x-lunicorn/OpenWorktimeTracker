import Foundation

struct BreakCalculator {

    let breakAfter6hMinutes: Int
    let breakAfter9hMinutes: Int

    init(
        breakAfter6hMinutes: Int = AppDefaults.breakAfter6hMinutes,
        breakAfter9hMinutes: Int = AppDefaults.breakAfter9hMinutes
    ) {
        self.breakAfter6hMinutes = breakAfter6hMinutes
        self.breakAfter9hMinutes = breakAfter9hMinutes
    }

    /// Required break in seconds based on ArbZG §4.
    /// `workTime` is gross work time minus manual pauses and idle pauses (actual time spent working).
    func requiredBreak(forWorkTime workTime: TimeInterval) -> TimeInterval {
        let hours = workTime / 3600.0
        if hours > 9.0 {
            return Double(breakAfter9hMinutes) * 60.0
        } else if hours > 6.0 {
            return Double(breakAfter6hMinutes) * 60.0
        }
        return 0
    }

    /// Auto break = max(0, required break - already taken pauses).
    /// This ensures that if the user already took enough manual breaks, no additional auto-break is added.
    func autoBreak(forWorkTime workTime: TimeInterval, alreadyPaused: TimeInterval) -> TimeInterval
    {
        let required = requiredBreak(forWorkTime: workTime)
        return max(0, required - alreadyPaused)
    }

    /// Net work time after all breaks.
    func netWorkTime(grossTime: TimeInterval, manualPause: TimeInterval, idlePause: TimeInterval)
        -> TimeInterval
    {
        let workBeforeAuto = grossTime - manualPause - idlePause
        let auto = autoBreak(forWorkTime: workBeforeAuto, alreadyPaused: manualPause + idlePause)
        return max(0, workBeforeAuto - auto)
    }
}

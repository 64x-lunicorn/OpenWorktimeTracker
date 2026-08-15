import Foundation

/// The configured minutes of Auto Break owed at each legal threshold.
///
/// A Workday cannot derive Net Work Time without these, which is what stops a
/// caller from silently falling back to the defaults.
struct AutoBreakRules {

    let after6hMinutes: Int
    let after9hMinutes: Int

    /// Resolved from user settings. The Settings module will take this over.
    static func resolved(from defaults: UserDefaults = .standard) -> AutoBreakRules {
        AutoBreakRules(
            after6hMinutes: defaults.object(forKey: AppSettingsKey.breakAfter6hMinutes) as? Int
                ?? AppDefaults.breakAfter6hMinutes,
            after9hMinutes: defaults.object(forKey: AppSettingsKey.breakAfter9hMinutes) as? Int
                ?? AppDefaults.breakAfter9hMinutes
        )
    }

    /// The Auto Break owed for a stretch of work, net of Pause already taken.
    ///
    /// The only place the ArbZG ladder is reached from.
    func autoBreak(
        forWorkTime workTime: TimeInterval,
        alreadyPaused: TimeInterval
    ) -> TimeInterval {
        BreakCalculator(
            breakAfter6hMinutes: after6hMinutes,
            breakAfter9hMinutes: after9hMinutes
        ).autoBreak(forWorkTime: workTime, alreadyPaused: alreadyPaused)
    }
}

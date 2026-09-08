import Foundation

/// The configured stretch of inactivity that ends an Idle Period.
///
/// Resolution guarantees a positive value, so callers never need a second
/// fallback on top of this one.
struct IdleThreshold {

    let minutes: Int

    init(minutes: Int) {
        self.minutes = minutes > 0 ? minutes : AppDefaults.idleThresholdMinutes
    }

    var seconds: TimeInterval { Double(minutes) * 60 }

    /// Resolved from user settings.
    static func resolved(from defaults: UserDefaults = .standard) -> IdleThreshold {
        IdleThreshold(
            minutes: defaults.object(forKey: AppSettingsKey.idleThresholdMinutes) as? Int
                ?? AppDefaults.idleThresholdMinutes
        )
    }
}

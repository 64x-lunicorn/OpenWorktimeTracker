import Foundation

/// Where a Workday's Net Work Time currently sits on the Threshold Ladder.
///
/// Named by meaning rather than by colour: the menu bar, the week history and
/// the log editor each paint the same level differently.
enum ThresholdLevel: Equatable {
    case normal
    case elevated
    case critical
}

/// The two Thresholds that recolour a Workday.
///
/// Distinct from the notification Thresholds, which fire at their own points and
/// are deliberately allowed to differ.
struct ThresholdLadder {

    let elevatedHours: Double
    let criticalHours: Double

    func level(forHours hours: Double) -> ThresholdLevel {
        if hours >= criticalHours { return .critical }
        if hours >= elevatedHours { return .elevated }
        return .normal
    }

    func level(for netWorkTime: TimeInterval) -> ThresholdLevel {
        level(forHours: netWorkTime / 3600.0)
    }

    /// Resolved from user settings.
    static func resolved(from defaults: UserDefaults = .standard) -> ThresholdLadder {
        ThresholdLadder(
            elevatedHours: defaults.object(forKey: SharedDefaults.orangeThresholdSettingKey)
                as? Double ?? SharedDefaults.orangeThresholdDefault,
            criticalHours: defaults.object(forKey: SharedDefaults.redThresholdSettingKey)
                as? Double ?? SharedDefaults.redThresholdDefault
        )
    }
}

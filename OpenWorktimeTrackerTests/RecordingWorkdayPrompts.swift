import Foundation

@testable import OpenWorktimeTracker

/// Test double for `WorkdayPromptPresenting`. Records every prompt
/// WorkdayManager asks for instead of opening a panel.
final class RecordingWorkdayPrompts: WorkdayPromptPresenting {
    private(set) var periods: [IdlePeriod] = []
    private(set) var maxHoursPrompts: [Double] = []
    private(set) var dismissCount = 0

    func show(idlePeriod: IdlePeriod, manager: WorkdayManager) {
        periods.append(idlePeriod)
    }

    func showMaxHoursPrompt(hours: Double, manager: WorkdayManager) {
        maxHoursPrompts.append(hours)
    }

    func dismiss() {
        dismissCount += 1
    }
}

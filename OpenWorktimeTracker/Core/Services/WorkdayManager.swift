import AppKit
import Foundation
import Observation
import WidgetKit

@Observable
final class WorkdayManager {

    // MARK: - State

    enum State: String {
        case notStarted
        case running
        case paused
        case ended
    }

    private(set) var state: State = .notStarted
    private(set) var currentEntry: TimeEntry?
    private(set) var displayTime: TimeInterval = 0
    private(set) var grossTime: TimeInterval = 0
    private(set) var autoBreak: TimeInterval = 0
    private(set) var manualPause: TimeInterval = 0
    private(set) var netTime: TimeInterval = 0

    // MARK: - Services

    let persistence = PersistenceManager()
    let idleDetector = IdleDetector()
    private let notifications = NotificationManager.shared

    private var breakCalculator: BreakCalculator {
        BreakCalculator(
            breakAfter6hMinutes: UserDefaults.standard.object(
                forKey: AppSettingsKey.breakAfter6hMinutes) as? Int
                ?? AppDefaults.breakAfter6hMinutes,
            breakAfter9hMinutes: UserDefaults.standard.object(
                forKey: AppSettingsKey.breakAfter9hMinutes) as? Int
                ?? AppDefaults.breakAfter9hMinutes
        )
    }

    private var timer: Timer?
    private var lastSaveTime: Date?

    // MARK: - Initialization

    func bootstrap() {
        NotificationManager.shared.requestPermission()
        registerForSleepWake()

        idleDetector.onPromptReady = { [weak self] prompt in
            guard let self else { return }
            DispatchQueue.main.async {
                IdlePromptWindowController.shared.show(promptInfo: prompt, manager: self)
            }
        }

        // Global keyboard shortcuts
        let shortcuts = GlobalShortcutManager.shared
        shortcuts.onPauseResume = { [weak self] in
            guard let self else { return }
            switch self.state {
            case .running: self.pause()
            case .paused: self.resume()
            case .notStarted: self.startNewDay()
            case .ended: break
            }
        }
        shortcuts.onEndDay = { [weak self] in
            guard let self else { return }
            if self.state == .running || self.state == .paused {
                self.endDay()
            }
        }
        shortcuts.register()

        persistence.syncWithCloud()
        evaluateWorkday()
    }

    // MARK: - Workday Detection

    private func evaluateWorkday() {
        let detector = WorkdayDetector(
            newDayStartHour: UserDefaults.standard.object(forKey: AppSettingsKey.newDayStartHour)
                as? Int
                ?? AppDefaults.newDayStartHour
        )

        let todayEntry = persistence.loadToday()
        let mostRecent = persistence.loadMostRecentEntry()

        let action = detector.evaluate(todayEntry: todayEntry, mostRecentEntry: mostRecent)

        switch action {
        case .continueExisting(let entry):
            currentEntry = entry
            switch entry.status {
            case .running:
                state = .running
                startTimer()
            case .paused:
                state = .paused
                startTimer()
            case .ended:
                state = .ended
                updateComputedValues()
            }

        case .startFreshDay:
            startNewDay()

        case .endPreviousAndStartNew(let previous, let suggestedEnd):
            // Auto-end the previous day and start new
            var ended = previous
            ended.status = .ended
            ended.endTime = suggestedEnd
            persistence.save(ended)
            startNewDay()

        case .dayAlreadyEnded(let entry):
            currentEntry = entry
            state = .ended
            updateComputedValues()
        }
    }

    // MARK: - Actions

    func startNewDay() {
        let entry = TimeEntry(startTime: Date())
        currentEntry = entry
        state = .running
        persistence.save(entry)
        startTimer()
        idleDetector.startMonitoring()
        notifications.sendNewDayNotification()
    }

    func pause() {
        guard state == .running, var entry = currentEntry else { return }
        entry.pauseStartedAt = Date()
        entry.status = .paused
        currentEntry = entry
        state = .paused
        persistence.save(entry)
    }

    func resume() {
        guard state == .paused, var entry = currentEntry else { return }
        if let pauseStart = entry.pauseStartedAt {
            entry.manualPauseSeconds += Date().timeIntervalSince(pauseStart)
        }
        entry.pauseStartedAt = nil
        entry.status = .running
        currentEntry = entry
        state = .running
        persistence.save(entry)
    }

    func endDay() {
        guard var entry = currentEntry else { return }

        // If paused, finalize the pause duration
        if state == .paused, let pauseStart = entry.pauseStartedAt {
            entry.manualPauseSeconds += Date().timeIntervalSince(pauseStart)
            entry.pauseStartedAt = nil
        }

        entry.status = .ended
        entry.endTime = Date()
        currentEntry = entry
        state = .ended
        persistence.save(entry)
        stopTimer()
        idleDetector.stopMonitoring()
    }

    func restartDay() {
        let entry = TimeEntry(startTime: Date())
        currentEntry = entry
        state = .running
        persistence.save(entry)
        startTimer()
        idleDetector.startMonitoring()
    }

    func updateNote(_ note: String) {
        guard var entry = currentEntry else { return }
        entry.note = note
        currentEntry = entry
        persistence.save(entry)
    }

    func updateStartTime(_ newStart: Date) {
        guard var entry = currentEntry else { return }
        if let end = entry.endTime, newStart > end { return }
        entry.startTime = newStart
        currentEntry = entry
        persistence.save(entry)
        updateComputedValues()
    }

    func updateEndTime(_ newEnd: Date) {
        guard var entry = currentEntry, state == .ended else { return }
        if newEnd < entry.startTime { return }
        entry.endTime = newEnd
        currentEntry = entry
        persistence.save(entry)
        updateComputedValues()
    }

    /// Estimated end time to reach a target of net work hours.
    /// Accounts for auto-break that will be added at 6h/9h thresholds.
    var estimatedEndTime: Date? {
        guard let entry = currentEntry, state == .running else { return nil }
        let targetHours =
            UserDefaults.standard.object(forKey: AppSettingsKey.normalNotificationHours)
            as? Double ?? AppDefaults.normalNotificationHours
        let targetSeconds = targetHours * 3600

        // Calculate how much gross time is needed to reach targetSeconds net
        // Net = Gross - ManualPause - IdlePause - AutoBreak
        // AutoBreak depends on (Gross - ManualPause - IdlePause)
        let alreadyPaused = entry.totalManualPause + entry.totalIdlePause
        let calc = breakCalculator

        // Estimate: target net + pauses already taken + auto-break for the total
        let estimatedWorkTime = targetSeconds
        let estimatedAutoBreak = calc.autoBreak(
            forWorkTime: estimatedWorkTime,
            alreadyPaused: alreadyPaused
        )
        let neededGross = targetSeconds + alreadyPaused + estimatedAutoBreak
        let currentGross = entry.grossTime
        let remaining = neededGross - currentGross

        guard remaining > 0 else { return nil }
        return Date().addingTimeInterval(remaining)
    }

    // MARK: - Idle Handling

    func handleIdleDecision(_ decision: IdleDecision.Decision) {
        guard var entry = currentEntry,
            let prompt = idleDetector.pendingPrompt
        else { return }

        let idleDecision = IdleDecision(
            idleStart: prompt.idleStart,
            idleEnd: prompt.idleEnd,
            decision: decision
        )
        entry.idleDecisions.append(idleDecision)
        currentEntry = entry
        persistence.save(entry)
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
    }

    func handleIdleDecisionAndEndDay() {
        guard var entry = currentEntry,
            let prompt = idleDetector.pendingPrompt
        else { return }

        // Record idle time as pause, then end the day at idle start
        let idleDecision = IdleDecision(
            idleStart: prompt.idleStart,
            idleEnd: prompt.idleEnd,
            decision: .pause
        )
        entry.idleDecisions.append(idleDecision)
        entry.status = .ended
        entry.endTime = prompt.idleStart
        if let pauseStart = entry.pauseStartedAt {
            entry.manualPauseSeconds += prompt.idleStart.timeIntervalSince(pauseStart)
            entry.pauseStartedAt = nil
        }
        currentEntry = entry
        state = .ended
        persistence.save(entry)
        stopTimer()
        idleDetector.dismissPrompt()
        idleDetector.stopMonitoring()
        IdlePromptWindowController.shared.dismiss()
    }

    func handleIdleDecisionAndRestart() {
        guard var entry = currentEntry,
            let prompt = idleDetector.pendingPrompt
        else { return }

        // End current day at idle start, then start a new day
        let idleDecision = IdleDecision(
            idleStart: prompt.idleStart,
            idleEnd: prompt.idleEnd,
            decision: .pause
        )
        entry.idleDecisions.append(idleDecision)
        entry.status = .ended
        entry.endTime = prompt.idleStart
        if let pauseStart = entry.pauseStartedAt {
            entry.manualPauseSeconds += prompt.idleStart.timeIntervalSince(pauseStart)
            entry.pauseStartedAt = nil
        }
        persistence.save(entry)
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
        startNewDay()
    }

    func handleNewDayFromIdle(endYesterdayAt: Date) {
        guard var entry = currentEntry,
            idleDetector.pendingPrompt != nil
        else { return }

        // End the old entry
        entry.status = .ended
        entry.endTime = endYesterdayAt
        if let pauseStart = entry.pauseStartedAt {
            entry.manualPauseSeconds += endYesterdayAt.timeIntervalSince(pauseStart)
            entry.pauseStartedAt = nil
        }
        persistence.save(entry)

        // Start fresh
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
        startNewDay()
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        updateComputedValues()
        checkThresholds()
        checkDateChange()
        autoSave()
    }

    private func updateComputedValues() {
        guard let entry = currentEntry else { return }

        grossTime = entry.grossTime
        manualPause = entry.totalManualPause

        let calc = breakCalculator
        let workBeforeAuto = entry.workTimeBeforeAutoBreak
        autoBreak = calc.autoBreak(
            forWorkTime: workBeforeAuto,
            alreadyPaused: entry.totalPause
        )
        netTime = max(0, workBeforeAuto - autoBreak)
        displayTime = netTime

        SharedDefaults.update(
            state: state.rawValue,
            netTime: netTime,
            grossTime: grossTime,
            startTime: entry.startTime,
            date: entry.date
        )
    }

    // MARK: - Threshold Notifications

    private func checkThresholds() {
        guard var entry = currentEntry,
            UserDefaults.standard.object(forKey: AppSettingsKey.notificationsEnabled) as? Bool
                ?? AppDefaults.notificationsEnabled
        else { return }

        let hours = netTime.inHours

        let normalH =
            UserDefaults.standard.object(forKey: AppSettingsKey.normalNotificationHours) as? Double
            ?? AppDefaults.normalNotificationHours
        let criticalH =
            UserDefaults.standard.object(forKey: AppSettingsKey.criticalNotificationHours)
            as? Double
            ?? AppDefaults.criticalNotificationHours
        let milestoneH =
            UserDefaults.standard.object(forKey: AppSettingsKey.milestoneNotificationHours)
            as? Double
            ?? AppDefaults.milestoneNotificationHours

        if hours >= milestoneH && !entry.notifiedThresholds.contains("milestone") {
            notifications.sendThresholdNotification(type: .milestone(hours: hours))
            entry.notifiedThresholds.insert("milestone")
            currentEntry = entry
            persistence.save(entry)
            // Show popup asking to end the day
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                IdlePromptWindowController.shared.showMaxHoursPrompt(hours: hours, manager: self)
            }
        } else if hours >= criticalH && !entry.notifiedThresholds.contains("critical") {
            notifications.sendThresholdNotification(type: .critical(hours: hours))
            entry.notifiedThresholds.insert("critical")
            currentEntry = entry
            persistence.save(entry)
        } else if hours >= normalH && !entry.notifiedThresholds.contains("normal") {
            notifications.sendThresholdNotification(type: .normal(hours: hours))
            entry.notifiedThresholds.insert("normal")
            currentEntry = entry
            persistence.save(entry)
        }
    }

    // MARK: - Date Change Detection

    private func checkDateChange() {
        guard let entry = currentEntry, state == .running else { return }
        let detector = WorkdayDetector(
            newDayStartHour: UserDefaults.standard.object(forKey: AppSettingsKey.newDayStartHour)
                as? Int
                ?? AppDefaults.newDayStartHour
        )
        let effectiveDate = detector.effectiveDateString(for: Date())
        if effectiveDate != entry.date {
            // Day changed while running — end old day and start new
            var ended = entry
            ended.status = .ended
            // End at midnight or at last known activity
            let midnight = Calendar.current.startOfDay(for: Date())
            ended.endTime = midnight
            if let pauseStart = ended.pauseStartedAt {
                ended.manualPauseSeconds += midnight.timeIntervalSince(pauseStart)
                ended.pauseStartedAt = nil
            }
            persistence.save(ended)
            startNewDay()
        }
    }

    // MARK: - Auto-Save

    private func autoSave() {
        let now = Date()
        if let last = lastSaveTime, now.timeIntervalSince(last) < 30 { return }
        if let entry = currentEntry {
            persistence.save(entry)
            lastSaveTime = now
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Sleep/Wake

    private func registerForSleepWake() {
        let wsnc = NSWorkspace.shared.notificationCenter
        wsnc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) {
            [weak self] _ in
            self?.handleSleep()
        }
        wsnc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) {
            [weak self] _ in
            self?.handleWake()
        }

        // Screen lock/unlock (covers lid close without sleep, fast user switching)
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.handleSleep()  // save state on lock
        }
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.handleWake()  // re-evaluate on unlock
        }
    }

    private func handleSleep() {
        // Save current state before sleep
        if let entry = currentEntry {
            persistence.save(entry)
        }
    }

    private func handleWake() {
        // Re-evaluate workday — might be a new day
        evaluateWorkday()
    }

    // MARK: - Menu Bar Display

    var menuBarTitle: String {
        switch state {
        case .notStarted:
            return "--:--"
        case .running:
            return displayTime.hoursMinutesFormatted
        case .paused:
            return "|| \(displayTime.hoursMinutesFormatted)"
        case .ended:
            return "\(displayTime.hoursMinutesFormatted)"
        }
    }

    var menuBarColor: MenuBarColor {
        let hours = netTime.inHours
        let redThreshold =
            UserDefaults.standard.object(forKey: AppSettingsKey.redThresholdHours) as? Double
            ?? AppDefaults.redThresholdHours
        let orangeThreshold =
            UserDefaults.standard.object(forKey: AppSettingsKey.orangeThresholdHours) as? Double
            ?? AppDefaults.orangeThresholdHours

        if hours >= redThreshold { return .red }
        if hours >= orangeThreshold { return .orange }
        return .normal
    }

    enum MenuBarColor {
        case normal, orange, red
    }
}

// MARK: - State Localization

extension WorkdayManager.State {
    var localizedLabel: String {
        switch self {
        case .notStarted: return String(localized: "state.notStarted")
        case .running: return String(localized: "state.running")
        case .paused: return String(localized: "state.paused")
        case .ended: return String(localized: "state.ended")
        }
    }
}

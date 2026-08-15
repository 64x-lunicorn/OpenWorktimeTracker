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
    private(set) var currentWorkday: Workday?
    private(set) var displayTime: TimeInterval = 0
    private(set) var grossTime: TimeInterval = 0
    private(set) var autoBreak: TimeInterval = 0
    private(set) var manualPause: TimeInterval = 0
    private(set) var netTime: TimeInterval = 0

    /// The Daily Log payload behind the current Workday.
    var currentEntry: TimeEntry? { currentWorkday?.payload }

    // MARK: - Services

    let persistence = PersistenceManager()
    let idleDetector = IdleDetector()
    private let notifications = NotificationManager.shared

    /// Pairs a Daily Log payload with the configured Auto Break Rules and
    /// Threshold Ladder. The one place configuration is resolved.
    func workday(for entry: TimeEntry) -> Workday {
        Workday(payload: entry)
    }

    private var timer: Timer?
    private var lastSaveTime: Date?
    private var hasBootstrapped = false
    private var sleepWakeObservers: [Any] = []

    // MARK: - Initialization

    func bootstrap() {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        registerForSleepWake()

        idleDetector.onPromptReady = { [weak self] prompt in
            guard let self else { return }
            DispatchQueue.main.async {
                guard self.state == .running || self.state == .paused else { return }
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

        registerForSettingsChanges()
        persistence.syncWithCloud()
        evaluateWorkday()
    }

    /// The held Workday carries resolved configuration, so a settings change has
    /// to be pushed into it rather than picked up on the next derivation.
    private func registerForSettingsChanges() {
        sleepWakeObservers.append(
            NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification, object: nil, queue: .main
            ) { [weak self] _ in
                guard let self, let workday = self.currentWorkday else { return }
                self.currentWorkday = workday.reconfigured()
                self.updateComputedValues()
            }
        )
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
            currentWorkday = workday(for: entry)
            switch entry.status {
            case .running:
                state = .running
                startTimer()
                idleDetector.startMonitoring()
            case .paused:
                state = .paused
                startTimer()
                idleDetector.startMonitoring()
            case .ended:
                state = .ended
                updateComputedValues()
            }

        case .startFreshDay:
            startNewDay()

        case .endPreviousAndStartNew(let previous, let suggestedEnd):
            // Auto-end the previous day and start new. `ended(at:)` closes any
            // Pause that was still open so the Net Work Time stays correct.
            persistence.save(workday(for: previous).ended(at: suggestedEnd).payload)
            startNewDay()

        case .dayAlreadyEnded(let entry):
            currentWorkday = workday(for: entry)
            state = .ended
            updateComputedValues()
        }
    }

    // MARK: - Actions

    func startNewDay() {
        let started = workday(for: TimeEntry(startTime: Date()))
        currentWorkday = started
        state = .running
        persistence.save(started.payload)
        startTimer()
        idleDetector.startMonitoring()
        notifications.sendNewDayNotification()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func pause() {
        guard state == .running, let current = currentWorkday else { return }
        let paused = current.paused(at: Date())
        currentWorkday = paused
        state = .paused
        persistence.save(paused.payload)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func resume() {
        guard state == .paused, let current = currentWorkday else { return }
        let resumed = current.resumed(at: Date())
        currentWorkday = resumed
        state = .running
        persistence.save(resumed.payload)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func endDay() {
        guard let current = currentWorkday else { return }

        let ended = current.ended(at: Date())
        currentWorkday = ended
        state = .ended
        persistence.save(ended.payload)
        stopTimer()
        idleDetector.stopMonitoring()
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func restartDay() {
        let restarted = workday(for: TimeEntry(startTime: Date()))
        currentWorkday = restarted
        state = .running
        persistence.save(restarted.payload)
        startTimer()
        idleDetector.startMonitoring()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateNote(_ note: String) {
        guard let current = currentWorkday else { return }
        let updated = current.withNote(note)
        currentWorkday = updated
        persistence.save(updated.payload)
    }

    func updateStartTime(_ newStart: Date) {
        guard let current = currentWorkday else { return }
        if let end = current.endTime {
            if newStart > end { return }
        } else if newStart > Date() {
            // Running/paused day: the start must not be in the future
            return
        }
        let updated = current.withStartTime(newStart)
        currentWorkday = updated
        persistence.save(updated.payload)
        updateComputedValues()
    }

    func updateEndTime(_ newEnd: Date) {
        guard let current = currentWorkday, state == .ended else { return }
        if newEnd < current.startTime { return }
        let updated = current.withEndTime(newEnd)
        currentWorkday = updated
        persistence.save(updated.payload)
        updateComputedValues()
    }

    func reloadCurrentEntry() {
        guard let current = currentWorkday else { return }
        let today = TimeEntry.dateString(from: Date())
        if current.date == today, let reloaded = persistence.load(for: today) {
            currentWorkday = workday(for: reloaded)
            state = State(rawValue: reloaded.status.rawValue) ?? .notStarted
            // Keep timer and idle monitoring in sync with the reloaded status
            switch state {
            case .running, .paused:
                startTimer()
                idleDetector.startMonitoring()
            case .notStarted, .ended:
                stopTimer()
                idleDetector.stopMonitoring()
            }
            updateComputedValues()
        }
    }

    /// Estimated end time to reach a target of net work hours.
    /// Accounts for auto-break that will be added at 6h/9h thresholds.
    var estimatedEndTime: Date? {
        guard let current = currentWorkday, state == .running || state == .paused else { return nil }
        let targetHours =
            UserDefaults.standard.object(forKey: AppSettingsKey.normalNotificationHours)
            as? Double ?? AppDefaults.normalNotificationHours
        let targetSeconds = targetHours * 3600

        // Calculate how much gross time is needed to reach targetSeconds net
        // Net = Gross - ManualPause - IdlePause - AutoBreak
        // AutoBreak depends on (Gross - ManualPause - IdlePause)
        let alreadyPaused = current.pause

        // Estimate: target net + pauses already taken + auto-break for the total
        let estimatedWorkTime = targetSeconds
        let estimatedAutoBreak = current.autoBreakRules.autoBreak(
            forWorkTime: estimatedWorkTime,
            alreadyPaused: alreadyPaused
        )
        let neededGross = targetSeconds + alreadyPaused + estimatedAutoBreak
        let currentGross = current.grossTime
        let remaining = neededGross - currentGross

        guard remaining > 0 else { return nil }
        return Date().addingTimeInterval(remaining)
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
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
        guard let current = currentWorkday else {
            grossTime = 0
            manualPause = 0
            autoBreak = 0
            netTime = 0
            displayTime = 0
            SharedDefaults.update(
                state: state.rawValue,
                netTime: 0,
                grossTime: 0,
                startTime: Date(),
                date: ""
            )
            return
        }

        grossTime = current.grossTime
        manualPause = current.pause
        autoBreak = current.autoBreak
        netTime = current.netWorkTime
        displayTime = netTime

        SharedDefaults.update(
            state: state.rawValue,
            netTime: netTime,
            grossTime: grossTime,
            startTime: current.startTime,
            date: current.date
        )
    }

    // MARK: - Threshold Notifications

    private var notificationsEnabled: Bool {
        UserDefaults.standard.object(forKey: AppSettingsKey.notificationsEnabled) as? Bool
            ?? AppDefaults.notificationsEnabled
    }

    private func checkThresholds() {
        guard let current = currentWorkday, state == .running || state == .paused else { return }

        let hours = netTime.inHours
        let notified = current.payload.notifiedThresholds

        let milestoneH =
            UserDefaults.standard.object(forKey: AppSettingsKey.milestoneNotificationHours)
            as? Double
            ?? AppDefaults.milestoneNotificationHours

        // The 10h milestone popup is a legal safeguard (ArbZG) and must appear
        // regardless of whether notifications are enabled.
        if hours >= milestoneH && !notified.contains("milestone") {
            let updated = current.markingNotified("milestone")
            currentWorkday = updated
            persistence.save(updated.payload)
            if notificationsEnabled {
                notifications.sendThresholdNotification(type: .milestone(hours: hours))
            }
            // Show popup asking to end the day
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                IdlePromptWindowController.shared.showMaxHoursPrompt(hours: hours, manager: self)
            }
            return
        }

        // Normal and critical notifications are only sent when enabled.
        guard notificationsEnabled else { return }

        let normalH =
            UserDefaults.standard.object(forKey: AppSettingsKey.normalNotificationHours) as? Double
            ?? AppDefaults.normalNotificationHours
        let criticalH =
            UserDefaults.standard.object(forKey: AppSettingsKey.criticalNotificationHours)
            as? Double
            ?? AppDefaults.criticalNotificationHours

        if hours >= criticalH && !notified.contains("critical") {
            notifications.sendThresholdNotification(type: .critical(hours: hours))
            let updated = current.markingNotified("critical")
            currentWorkday = updated
            persistence.save(updated.payload)
        } else if hours >= normalH && !notified.contains("normal") {
            notifications.sendThresholdNotification(type: .normal(hours: hours))
            let updated = current.markingNotified("normal")
            currentWorkday = updated
            persistence.save(updated.payload)
        }
    }

    // MARK: - Date Change Detection

    private func checkDateChange() {
        guard let current = currentWorkday, state == .running || state == .paused else { return }
        let detector = WorkdayDetector(
            newDayStartHour: UserDefaults.standard.object(forKey: AppSettingsKey.newDayStartHour)
                as? Int
                ?? AppDefaults.newDayStartHour
        )
        let effectiveDate = detector.effectiveDateString(for: Date())
        if effectiveDate != current.date {
            // Dismiss any pending idle prompt — it references the old day
            idleDetector.dismissPrompt()
            IdlePromptWindowController.shared.dismiss()

            let wasPaused = (state == .paused)

            // Day changed — end old day at midnight, closing any open Pause
            let midnight = Calendar.current.startOfDay(for: Date())
            persistence.save(current.ended(at: midnight).payload)

            if wasPaused {
                // The user was paused across midnight (not actively working) —
                // don't auto-start a running day, which would wrongly count the
                // night as work. Reset to a clean, idle slate instead.
                currentWorkday = nil
                state = .notStarted
                stopTimer()
                idleDetector.stopMonitoring()
                updateComputedValues()
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                startNewDay()
            }
        }
    }

    // MARK: - Auto-Save

    private func autoSave() {
        let now = Date()
        if let last = lastSaveTime, now.timeIntervalSince(last) < 30 { return }
        if let current = currentWorkday {
            persistence.save(current.payload)
            lastSaveTime = now
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Sleep/Wake

    private func registerForSleepWake() {
        let wsnc = NSWorkspace.shared.notificationCenter
        sleepWakeObservers.append(
            wsnc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                self?.handleSleep()
            }
        )
        sleepWakeObservers.append(
            wsnc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                self?.handleWake()
            }
        )

        // Screen lock/unlock (covers lid close without sleep, fast user switching)
        let dnc = DistributedNotificationCenter.default()
        sleepWakeObservers.append(
            dnc.addObserver(
                forName: NSNotification.Name("com.apple.screenIsLocked"),
                object: nil, queue: .main
            ) { [weak self] _ in
                self?.handleSleep()  // save state on lock
            }
        )
        sleepWakeObservers.append(
            dnc.addObserver(
                forName: NSNotification.Name("com.apple.screenIsUnlocked"),
                object: nil, queue: .main
            ) { [weak self] _ in
                self?.handleWake()  // re-evaluate on unlock
            }
        )
    }

    private func handleSleep() {
        // Save current state before sleep
        if let current = currentWorkday {
            persistence.save(current.payload)
        }
    }

    private func handleWake() {
        // Re-evaluate workday — might be a new day.
        // Delay slightly so IdleDetector's screenDidUnlock fires first and
        // can prepare its prompt before we potentially reset state.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            // If the idle detector raised a prompt, let the user's decision drive
            // the day transition instead of racing it with an auto-evaluation.
            if self.idleDetector.pendingPrompt != nil { return }
            self.evaluateWorkday()
        }
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

    var thresholdLevel: ThresholdLevel {
        (currentWorkday?.thresholds ?? .resolved()).level(for: netTime)
    }

    /// Exports every Daily Log, deriving Net Work Time with the configured rules.
    func exportCSV() -> URL? {
        persistence.exportCSV(autoBreakRules: .resolved(), thresholds: .resolved())
    }
}

// MARK: - Idle Handling

extension WorkdayManager {

    func handleIdleDecision(_ decision: IdleDecision.Decision) {
        guard let current = currentWorkday,
            let prompt = idleDetector.pendingPrompt
        else { return }

        let updated = current.recording(
            IdleDecision(idleStart: prompt.idleStart, idleEnd: prompt.idleEnd, decision: decision)
        )
        currentWorkday = updated
        persistence.save(updated.payload)
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
    }

    func handleIdleDecisionAndEndDay() {
        guard let current = currentWorkday,
            let prompt = idleDetector.pendingPrompt
        else { return }

        // Record idle time as pause, then end the day at idle start
        let ended =
            current
            .recording(
                IdleDecision(idleStart: prompt.idleStart, idleEnd: prompt.idleEnd, decision: .pause)
            )
            .ended(at: prompt.idleStart)
        currentWorkday = ended
        state = .ended
        persistence.save(ended.payload)
        stopTimer()
        idleDetector.dismissPrompt()
        idleDetector.stopMonitoring()
        IdlePromptWindowController.shared.dismiss()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func handleIdleDecisionAndRestart() {
        guard let current = currentWorkday,
            let prompt = idleDetector.pendingPrompt
        else { return }

        // End current day at idle start, then start a new day
        let ended =
            current
            .recording(
                IdleDecision(idleStart: prompt.idleStart, idleEnd: prompt.idleEnd, decision: .pause)
            )
            .ended(at: prompt.idleStart)
        persistence.save(ended.payload)
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
        startNewDay()
    }

    func handleNewDayFromIdle(endYesterdayAt: Date) {
        guard let current = currentWorkday,
            idleDetector.pendingPrompt != nil
        else { return }

        persistence.save(current.ended(at: endYesterdayAt).payload)

        // Start fresh
        idleDetector.dismissPrompt()
        IdlePromptWindowController.shared.dismiss()
        startNewDay()
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

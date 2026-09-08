# Changelog

All notable changes to OpenWorktimeTracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Changes collected on 2026-09-08.

### Added

- Optional `lastActivityTime` in daily logs, allowing unfinished days to end at the last recorded activity after an overnight restart; older JSON logs remain readable.
- Validated, timestamped widget snapshots that publish time, state, work date, target, and thresholds together through App Group storage or an atomic file fallback.
- Regression coverage for workday boundaries, sleep/wake ordering, idle decisions, failed and stale log mutations, widget snapshots, native menu actions, and editing shortcuts.
- Compact-layout rendering tests covering German and English, light and dark appearances, and overnight idle prompts.
- VS Code Debug build task with complete local ad-hoc signing, without changing release signing or requiring provisioning-only entitlements.

### Changed

- Replaced the SwiftUI application/`MenuBarExtra` lifecycle with an AppKit application, native `NSStatusItem`, and `NSPopover` hosting the existing SwiftUI dashboard; settings and standard editing shortcuts remain available.
- Improved readability with larger typography, stronger light-mode contrast, and a wider, shorter dashboard with permanently visible action buttons.
- Made Pause/Resume the primary action, clarified secondary day actions, and added accessible labels and native button styles.
- Redesigned idle and maximum-hours prompts with clearer consequences, overnight dates, localized durations, and readable button subtitles.
- Replaced custom start/end time inputs with bounded native time pickers and keyboard shortcuts; clarified goal completion and automatic break deductions.
- Improved settings accessibility, kept break thresholds consistent, exposed the selectable log-folder path, and clarified how the daily goal affects progress and estimated completion.
- Standardized history, summary, and fractional widget target durations as `HH:MM`, and localized widget metadata.
- Added a persistent Save/Discard footer, unsaved/invalid-state feedback, keyboard saving, and clearer empty states to the log editor.
- Centralized workday calculations, finalization, and idle decisions in the workday model and manager, with injectable clock, daily-log store, idle detector, prompt presenter, and widget store for deterministic tests.
- Updated feature, workday-detection, and architecture ownership documentation.
- Grouped manager methods and split lifecycle/mutation tests into a dedicated suite to keep the expanded code within SwiftLint's error limits without changing behavior.

### Fixed

- Restored native, wallpaper-aware menu-bar contrast below the thresholds. Orange/red states now render as non-template images so macOS menu-bar compositing no longer turns their icon and time black; colors update with system appearance and reset below the thresholds.
- Fixed cramped numeric settings columns in General and Notifications by hiding duplicate field labels while preserving their accessibility names; German and English rows now remain readable in light and dark appearances.
- Menu-bar clicks failed in the tested multi-display setup even with a native button inside the SwiftUI app lifecycle; the native AppKit startup path now receives real clicks and opens the dashboard.
- Tracking now starts at application launch without requiring the dashboard to open, and completed-day totals freeze immediately at the recorded end.
- Repeated starts no longer overwrite existing work; continuing an ended day preserves its entry and counts the intervening gap as a pause.
- Creating, loading, editing, and splitting logs now use the same effective workday boundary, preserving work between midnight and the configured start hour.
- Overnight idle decisions survive timer ticks and wake/unlock notifications; explicitly paused days do not silently accumulate overnight work or start again while the screen is locked.
- Sleep, wake, lock, and unlock handling is ordered without a timing-based delay, preserves pending idle periods, and flushes pending log writes before sleep.
- Manual and idle pauses are no longer deducted twice; overlapping idle pauses are merged and clipped to the actual work interval, including an early end at idle start.
- Starting a new day after an idle decision uses the return time rather than the later prompt-response time; ending before the start is clamped safely.
- Log editor saves and deletes now validate and reconcile against current tracking state, preventing stale drafts from reopening, recreating, or overwriting newer entries.
- Failed saves/deletes preserve the draft, stored data, and tracking state and display an error; success is reported only after the local operation completes. History reads and deletes wait for queued writes.
- Deleting today's log stops tracking and clears the widget without recreating the entry; deleting a historical log leaves the current idle decision intact.
- Widget timers stay anchored to the measurement timestamp instead of their later read time, paused/ended states remain frozen, and state changes publish current totals and settings together.

## [0.6.0] - 2026-07-09

### Fixed

- Idle prompt and max-hours popup could still appear after the workday was ended — `onPromptReady` callback now guards against `state == .ended`, `checkThresholds()` skips ended/not-started states, and `endDay()` dismisses any open prompt window
- `stopMonitoring()` left a stale `pendingPrompt` that could block `handleWake()` from re-evaluating the workday — now cleared on stop

### Changed

- Action buttons layout: merged the `...` menu into the same row as Pause/Resume and End Day buttons (was a separate row, looking disconnected)
- Idle prompt "End Day" button now shows the exact end time and net work hours (e.g. "Tag beenden um 09:52 — nach 05:22 Arbeitszeit")
- Idle prompt "Restart" button now shows what will happen (e.g. "Tag endet um 09:52, neuer Tag beginnt")

## [0.5.0] - 2026-07-08

### Fixed

- Idle detection never started when the app resumed an already-running day on launch (only `startNewDay`/`restartDay` started it) — now also started in the `continueExisting` path and on `reloadCurrentEntry`
- Date change not detected while paused — the entry could stick to the previous day; midnight rollover is now handled when paused and no longer counts the night as work
- Previous day auto-ended via `endPreviousAndStartNew` did not finalize an open pause, skewing net time
- `reloadCurrentEntry()` did not keep the timer or idle monitoring in sync with the reloaded status
- `updateStartTime()` allowed a start time in the future on a running day
- Notification thresholds could become inconsistent (`normal > critical`) when raising the normal hours — thresholds now cascade
- 10h ArbZG safeguard popup was suppressed when notifications were disabled — now always shown
- `IdleDetector` removed and re-added its lock/unlock observers on every start/stop, which could tear down an in-flight unlock handler — observers are now registered once and gated by a monitoring flag; `handleWake()` also defers to a pending idle prompt instead of racing it
- Widget showed a frozen time and requested a reload every minute (exhausting WidgetKit's budget) — running time now counts up live via `Text(timerInterval:)` with budget-friendly refresh intervals
- `DateFormatter` was re-allocated on every call in hot paths (timer tick, list rows, widget) — now cached
- Estimated end time (ETA) disappeared while paused — now stays visible and shifts as the pause grows

### Changed

- Consolidated the unit-test suite from 12 files (a base and an "extended" file per unit) into 6, removing duplicated fixtures and redundant cases — 152 tests, full coverage retained

## [0.4.0] - 2026-06-19

### Fixed

- `bootstrap()` called on every menu bar popover appearance causing duplicate observer registrations and repeated workday evaluation
- Timer scheduled on wrong RunLoop when called from non-main thread — now explicitly uses `RunLoop.main` with `.common` mode
- `endDay()`, `startNewDay()`, `restartDay()`, and idle decision handlers missing Widget reload — widget showed stale state
- `IdleDetector.idleThresholdSeconds` returned 0 when UserDefaults key not set (using `integer(forKey:)` which defaults to 0) — now falls back to `AppDefaults.idleThresholdMinutes`
- Race condition between `handleWake()` and `IdleDetector.screenDidUnlock()` — wake now delays 0.5s so idle prompt can prepare first
- Sleep/wake notification observer tokens not retained — could be deallocated prematurely; now stored in array
- `PersistenceManager.load(for:)` could read stale data during concurrent save — now drains save queue before reading
- `LogEditorView` array-index binding (`$entries[index]`) could crash if entries mutated during edit — replaced with safe `Binding(get:set:)`

## [0.3.0] - 2026-04-29

### Added

- Dependabot configuration for automated dependency updates (Swift/SPM, GitHub Actions, npm/docs)
- 100+ new unit tests across 6 extended test files (165 total tests)
  - `PersistenceManagerExtendedTests` — delete, loadAll, loadLastDays, export CSV, corrupt file handling, concurrent saves
  - `WorkdayDetectorExtendedTests` — suggestEndTime edge cases, midnight boundaries, custom new-day hour
  - `IdleDetectorExtendedTests` — duplicate prompt prevention, dismiss flow, formatting edge cases
  - `WorkdayManagerExtendedTests` — idle handling, state consistency, menu bar title, computed values
  - `BreakCalculatorExtendedTests` — negative inputs, boundary precision, long work days, custom thresholds
  - `TimeEntryExtendedTests` — Codable round-trips, IdleDecision mutability, edge cases

### Fixed

- Widget not updating on pause/resume (missing `WidgetCenter.shared.reloadAllTimelines()` calls)
- Force unwrap crash in `WorkdayDetector.effectiveDateString(for:)` when calendar returns nil
- `suggestEndTime` could return a time before entry start (e.g., 18:00 default for entries starting at 20:00)
- Idle prompt window not dismissed when user closes via X button (added `NSWindowDelegate`)
- Duplicate idle prompts firing when a prompt is already pending (added `pendingPrompt == nil` guards)
- Midnight date-change race condition: stale idle prompt referencing yesterday's context now dismissed before transition
- Silent data loss on save failures: replaced `try?` with proper error logging via `os.log`
- Stale security-scoped bookmark not renewed: bookmark now auto-refreshed when marked stale

## [0.2.0] - 2026-04-20

### Added

- Log Editor window for editing historical work time entries (start/end time, pauses, idle decisions, notes, delete)
- Log Editor accessible via "Edit Log..." in the menu bar popup
- Idle pauses (from idle prompt) now visible in the "Pauses" metric card (combined with manual pauses)
- `PersistenceManager.delete(for:)` method for removing log entries
- `WorkdayManager.reloadCurrentEntry()` for syncing edits to today's entry

### Fixed

- Notifications not showing: added `UNUserNotificationCenterDelegate` so banners appear for menu bar apps (always in foreground)
- Notifications: removed `.defaultCritical` sound and `.critical`/`.timeSensitive` interruption levels (require Apple entitlement)
- Notifications: permission request moved to `applicationDidFinishLaunching` for reliable timing
- Notifications: added error logging for permission and delivery failures
- Idle pauses were not displayed in the UI despite being correctly calculated
- Auto-Pause metric card removed (value is already reflected in net time)

### Changed

- "Manual Pause" metric card renamed to "Pauses" (now includes both manual and idle pauses)
- Metric card layout simplified to 2×2 grid (Start, Gross, Pauses, ETA/End)
- `IdleDecision.decision` changed from `let` to `var` for editability in Log Editor
- `DEVELOPMENT_TEAM` added to both targets in `project.yml` for proper widget code signing

## [0.1.0] - 2026-04-17

### Added

- Menu bar app with live net work time display
- Automatic workday detection (new day, overnight, sleep/wake)
- ArbZG-compliant auto-break calculation (configurable thresholds)
- Idle detection with 4-option user prompt (work time, break, end day, restart)
- 10h milestone popup asking to end day or continue
- Threshold notifications (normal at 8h, critical at 9.83h, milestone at 10h)
- Daily JSON log files in Application Support
- Settings window (appearance, breaks, notifications, idle, startup)
- Input validation for all settings fields
- Launch at Login via SMAppService
- Sparkle auto-updates (EdDSA signed)
- CSV export
- Global keyboard shortcuts (Ctrl+Option+P pause/resume, Ctrl+Option+E end day)
- Weekly/monthly summary statistics with overtime tracking
- 7-day history bar chart in popover
- iCloud sync for log files
- macOS Widget (WidgetKit) with configurable thresholds and localization
- App Group data sharing between app and widget
- EN/DE localization (full coverage)
- Accessibility labels for VoiceOver support
- GitHub Actions CI/CD (build, test, sign, notarize, release DMG)
- Astro/Starlight documentation site

### Fixed

- State machine correctly handles `.ended` entries on app restart
- Force unwrap crash in PersistenceManager default directory
- Security-scoped resource leak in custom log folder access
- Idle detection race condition between timer and screen lock
- Settings window opens reliably via `@Environment(\.openSettings)`
- Note text syncs correctly on day change
- MetricCards start/end popovers use independent state
- Start/end time validation prevents invalid edits
- State labels localized (no raw enum values)
- WeekHistoryView uses `Locale.current` for display formatting
- ProgressBar percentage clamped to 100%
- Async file I/O prevents main thread blocking
- PersistenceManager tests use isolated temp directory
- create-dmg.sh uses proper error handling instead of `|| true`

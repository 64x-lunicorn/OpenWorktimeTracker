# Changelog

All notable changes to OpenWorktimeTracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

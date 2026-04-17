# Changelog

All notable changes to OpenWorktimeTracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

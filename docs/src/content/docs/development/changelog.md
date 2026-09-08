---
title: Changelog
description: All notable changes to OpenWorktimeTracker.
---

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

- Restored native, wallpaper-aware menu-bar text and icon contrast instead of forcing the app's label color; orange/red threshold colors remain intact and clear again below the thresholds.
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

## Earlier releases

See the [complete release history](https://github.com/64x-lunicorn/OpenWorktimeTracker/blob/main/CHANGELOG.md) for versions 0.1.0 through 0.6.0.

# OpenWorktimeTracker — Copilot Instructions

## Project Overview
**OpenWorktimeTracker** is a native macOS menu bar app (SwiftUI + AppKit hybrid) that automatically tracks daily working hours. It runs as a `MenuBarExtra` (no Dock icon, `LSUIElement = YES`), auto-starts via `SMAppService` at login, and persists data as daily JSON files.

## Tech Stack
- **Language**: Swift 5.9+ (uses `@Observable` macro)
- **UI**: SwiftUI with `MenuBarExtra` (`.window` style) + `Settings` scene
- **Target**: macOS 14.0+ (Sonoma)
- **Dependencies**: Sparkle 2 (auto-updates via SPM), everything else native
- **Build**: XcodeGen → Xcode project from `project.yml`
- **CI/CD**: GitHub Actions (build, test, sign, notarize, release DMG)

## Architecture
```
OpenWorktimeTracker/
├── App/           — @main entry, AppDelegate (sleep/wake, Sparkle)
├── Core/
│   ├── Models/    — TimeEntry, AppSettings (Codable structs)
│   └── Services/  — WorkdayManager (@Observable state machine),
│                    BreakCalculator (ArbZG §4), IdleDetector (IOKit),
│                    WorkdayDetector (new-day logic), NotificationManager,
│                    PersistenceManager (JSON in App Support)
├── Views/         — MenuBarView (popover), SettingsView, IdlePromptView
│   └── Components/— ProgressBarView, GlassContainer, ActionButton
├── Design/        — DesignTokens (adaptive colors, typography)
├── Resources/     — Info.plist, Entitlements, Assets
└── Utilities/     — Date+Extensions
```

## Key Concepts
- **WorkdayManager** is the central `@Observable` state machine: `.notStarted` → `.running` ↔ `.paused` → `.ended`
- **WorkdayDetector** handles automatic new-day detection (overnight idle, sleep/wake, app restart). It should minimize user interaction — auto-start new days, auto-end previous days.
- **BreakCalculator** implements German ArbZG §4: >6h work → 30min break, >9h → 45min break. Thresholds are user-configurable.
- **IdleDetector** uses `CGEventSource.secondsSinceLastEventType` to detect inactivity. After idle, shows a prompt letting the user decide: "Was this work time (meeting) or a break?"
- **PersistenceManager** stores one JSON file per day in `~/Library/Application Support/OpenWorktimeTracker/logs/`
- Design follows the "Ethereal Chronometer" design system: glassmorphism, tonal depth, no hard borders.

## Conventions
- Use `@Observable` (not `ObservableObject`) for state management
- Use `@Environment(WorkdayManager.self)` for dependency injection
- Use `@AppStorage` for user settings
- All time calculations use `TimeInterval` (seconds), display as `HH:MM`
- File-per-day naming: `YYYY-MM-DD.json`
- German ArbZG break rules are the default but configurable
- Menu bar shows net work time (after breaks), color-coded by threshold
- No Dock icon — pure menu bar app

## Testing
- Unit tests for `BreakCalculator` (edge cases: exactly 6h, 6h01, 9h, 9h01)
- Unit tests for `WorkdayDetector` (new day, overnight, resume)
- Unit tests for `PersistenceManager` (JSON round-trip)
- Unit tests for `WorkdayManager` (state transitions)
- Build: `make test` or `xcodebuild test`

## Don'ts
- Don't use Core Data or SQLite — use plain JSON files
- Don't add external dependencies beyond Sparkle
- Don't use `ObservableObject` / `@Published` — use `@Observable`
- Don't use hard-coded colors — use DesignTokens
- Don't create Dock windows — this is a menu bar-only app

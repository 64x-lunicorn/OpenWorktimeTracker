---
title: Features Overview
description: Everything OpenWorktimeTracker can do for you.
---

OpenWorktimeTracker is designed to track your work hours **without getting in the way**. Here is what it does:

## Core Features

### Automatic Tracking
The app starts tracking when you open your Mac and stops when you end your day. No buttons to press, no timers to start manually.

### Smart Workday Detection
The app detects new workdays automatically by evaluating:
- Whether it is a new calendar day
- Whether the Mac was idle overnight or during sleep
- Whether the previous day's entry is still running

[Learn more about workday detection](/features/workday-detection/)

### ArbZG Break Calculation
Automatic break deduction according to German labor law (Arbeitszeitgesetz SS4):
- More than 6 hours of work: 30 minutes break
- More than 9 hours of work: 45 minutes break

All thresholds are configurable. Manual pauses are counted against the required break.

[Learn more about break calculation](/features/breaks/)

### Idle Detection
Uses macOS system-level idle detection (`CGEventSource`) to notice when you step away. When you return, a prompt lets you classify the time.

[Learn more about idle detection](/features/idle-detection/)

### Threshold Notifications
Get notified at configurable work time thresholds:
- **Normal** (default 8h): "Regular hours reached"
- **Critical** (default 9h 50m): "Time to go!"
- **Milestone** (default 10h): "Maximum reached!"

[Learn more about notifications](/features/notifications/)

### Data Persistence
Daily work logs stored as human-readable JSON files. Export to CSV anytime.

[Learn more about data and export](/features/data/)

### Desktop Widget
The app publishes status, times, targets, and color thresholds together with
their measurement timestamp. The widget reads this as one snapshot, so it cannot
combine fields from different updates. Running timers count from the original
measurement, not from when WidgetKit eventually reads it; paused and ended times
remain fixed. Progress and colors catch up when the timeline refreshes.

Between refreshes, a running timer extrapolates the last measured Net Work Time;
new Auto Break deductions or Idle Decisions appear with the next app snapshot
and widget refresh. If no readable snapshot exists, the widget asks you to open
the app rather than inventing a running state. After upgrading from the old
per-field format, launch the app once to publish the new format.

## Design

### Everyday Controls

- Pause, resume, and end-day actions stay visible below the scrollable menu bar content.
- History and summary durations use `HH:MM`, matching the main timer.
- Any additional Auto Break deduction is shown separately from recorded pauses.
- Idle prompts explain what each choice does and include dates for overnight periods.
- Start and end times use native time fields with keyboard-friendly save and cancel actions.
- The log editor keeps Save and Discard visible while scrolling, marks unsaved changes,
  and explains invalid time entries. Use **Command-S** to save.
- The regular-hours setting also defines the daily goal and estimated end time,
  even when notifications are disabled. Fractional-hour goals are preserved in the widget.

OpenWorktimeTracker follows the **Ethereal Chronometer** design system:
- Glassmorphism with tonal depth
- Adaptive light and dark mode
- No hard borders -- smooth gradients and blurs
- Consistent design tokens for colors and typography

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| SwiftUI + AppKit | Hybrid UI framework |
| `@Observable` | Swift 5.9 state management |
| AppKit lifecycle + `NSStatusItem` / `NSPopover` | Native menu bar event handling with SwiftUI dashboard and settings views |
| `SMAppService` | Login Item (no helper app) |
| `CGEventSource` | Hardware-level idle detection |
| `UNUserNotificationCenter` | Native notifications |
| Sparkle 2 | EdDSA-signed auto-updates |
| XcodeGen | Xcode project from YAML |
| GitHub Actions | CI/CD with code signing |

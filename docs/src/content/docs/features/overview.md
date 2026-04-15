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

## Design

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
| `MenuBarExtra` | Native menu bar integration |
| `SMAppService` | Login Item (no helper app) |
| `CGEventSource` | Hardware-level idle detection |
| `UNUserNotificationCenter` | Native notifications |
| Sparkle 2 | EdDSA-signed auto-updates |
| XcodeGen | Xcode project from YAML |
| GitHub Actions | CI/CD with code signing |

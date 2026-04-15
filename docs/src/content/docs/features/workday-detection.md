---
title: Workday Detection
description: How OpenWorktimeTracker automatically detects and manages new workdays.
---

## Overview

One of the core features of OpenWorktimeTracker is **automatic workday detection**. The app should require as little manual interaction as possible -- when you open your Mac in the morning, it should just work.

## Detection Logic

The `WorkdayDetector` evaluates the current state and returns one of four actions:

| Action | When | What happens |
|--------|------|-------------|
| `continueExisting` | Today's entry exists and is running/paused | Resume tracking |
| `startFreshDay` | No entry exists for today, no previous day running | Start a new workday |
| `endPreviousAndStartNew` | Previous day's entry is still running | End yesterday, start today |
| `dayAlreadyEnded` | Today's entry exists and is ended | Show completed state |

## When Does Detection Run?

The workday detector is evaluated at these points:

1. **App launch** -- when the app starts or restarts
2. **Wake from sleep** -- when the Mac wakes from sleep/lid open
3. **Timer tick** -- periodically checks if the date has changed
4. **Idle return** -- when the user returns from an idle period that crosses midnight

## New Day Start Hour

The app uses a configurable **new day start hour** (default: 4:00 AM) to determine when a new day begins. This means:

- Working past midnight? The app considers it the same workday until 4 AM
- Opening your Mac at 3 AM after overnight idle? Still counts as "yesterday"
- Opening at 5 AM? New workday starts

This prevents accidental day splits for people who occasionally work late.

## Scenarios

### Scenario 1: Normal Morning Start

1. You ended yesterday's workday normally
2. You open your Mac at 8:00 AM
3. No previous entry running, no today entry
4. **Action**: `startFreshDay` -- new workday begins at 8:00 AM

### Scenario 2: Forgot to End Day

1. You left your Mac open yesterday, timer still running
2. You return at 8:00 AM
3. Yesterday's entry is still in `.running` state
4. **Action**: `endPreviousAndStartNew`
5. Idle prompt shows: "New workday detected. End yesterday at ___?"
6. You pick an end time for yesterday
7. Today starts automatically

### Scenario 3: Mac Sleep Overnight

1. You close your Mac lid at 18:00
2. You open it at 8:00 the next morning
3. `AppDelegate` receives the wake notification
4. WorkdayDetector evaluates: previous day running, new date
5. **Action**: `endPreviousAndStartNew`

### Scenario 4: Working Past Midnight

1. You are working at 23:30
2. The clock passes midnight
3. Timer tick detects date change
4. Since it is before 4:00 AM (new day start hour), tracking continues on the current day
5. At 1:00 AM you end your day manually -- it is still counted as the previous calendar day

### Scenario 5: Resume After Pause

1. You paused your timer yesterday and closed the lid
2. Today: entry exists for yesterday in `.paused` state
3. **Action**: `endPreviousAndStartNew`

## Configuration

The new day start hour is currently set to 4:00 AM. This will be configurable in a future release.

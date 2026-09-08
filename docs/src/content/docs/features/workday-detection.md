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
2. **Wake and unlock** -- once the Mac is both awake and unlocked
3. **Timer tick** -- periodically checks if the date has changed
4. **Idle return** -- when the user returns from an idle period that crosses midnight

## New Day Start Hour

The app uses a configurable **new day start hour** (default: 4:00 AM) to determine when a new day begins. This means:

- Working past midnight? The app considers it the same workday until 4 AM
- Opening your Mac at 3 AM after overnight idle? Still counts as "yesterday"
- Opening at 5 AM? New workday starts

This prevents accidental day splits for people who occasionally work late.

The same effective date is used for creating, loading, and updating Daily Logs.
Active work crossing the boundary is split at that hour, not at midnight.
An unresolved idle period postpones the split until the user decides how to count it.

## Ending and Continuing

- Tracking starts when the app launches; opening the menu is not required.
- Ending a day immediately freezes its displayed totals at the recorded end time.
- **Continue** reopens the same Daily Log, preserving its start, notes, and pauses.
  The interval between ending and continuing is counted as a pause.
- A repeated start does not overwrite an existing day.
- After a completed day, the next effective day starts on activity or wake.
- An explicitly paused day is not turned into work merely because the clock crosses
  the boundary. Use **Start day** or **Resume** when returning to work.

New logs also record an optional `lastActivityTime`. After an app restart on a
later day, an unfinished day can be closed using that saved activity instead of
guessing 18:00. Older logs remain readable and retain the legacy estimate when
no activity timestamp is available.

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
3. `WorkdayManager` processes sleep/wake and lock/unlock in order, without a timed delay
4. Once awake and unlocked, the overnight Idle Period is presented before any day transition
5. Your Idle Decision determines whether that interval was work, a pause, or the end of yesterday
6. Duplicate wake/unlock notifications do not discard or duplicate the prompt

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

## Editing Daily Logs

The log editor validates and merges changes through `WorkdayManager`, preserving
newer tracking updates. Saving is confirmed only after the local file write
finishes. A failed save leaves the draft available and displays an error.
Deletion updates tracking and history only after the file adapter confirms it;
deleting an older Daily Log does not dismiss a current Idle Decision.

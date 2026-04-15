---
title: Quick Start
description: Start tracking your work time in under a minute.
---

## How It Works

OpenWorktimeTracker is a **set-it-and-forget-it** app. Once installed, your typical workflow is:

1. **Open your Mac** -- the app starts automatically (Login Item)
2. **Work normally** -- the timer runs in the menu bar showing your net time
3. **Take breaks** -- idle detection asks if inactive time was a break or a meeting
4. **Get notified** -- alerts at your configured thresholds (e.g., 8h, 10h)
5. **Day ends** -- click "End Day" or let it auto-detect overnight
6. **Next morning** -- a new workday starts automatically

## Menu Bar States

The menu bar icon shows your current net work time with color coding:

| State | Display | Color |
|-------|---------|-------|
| Working < 8h | `07:41` | Default |
| Working > Orange threshold | `08:15` | Orange |
| Working > Red threshold | `09:45` | Red |
| Paused | `[paused] 07:41` | Default |
| Day ended | `[done] 08:15` | Default |

## The Popover

Click the menu bar icon to open the popover. It shows:

- **Timer display** -- large, readable net work time
- **Progress bar** -- visual progress toward your daily target
- **Metric cards** -- gross time, break time, start time
- **Notes field** -- optional daily notes
- **Action buttons** -- Pause/Resume, End Day, Settings

## Key Interactions

### Pause and Resume

Click the **Pause** button in the popover to manually pause tracking. Click **Resume** to continue. Manual pauses are tracked separately from auto-breaks.

### End Day

Click **End Day** to finish your workday. The app will save the final times and stop the timer. The next morning, a new workday starts automatically.

### Idle Prompt

When the app detects you have been inactive (default: 5 minutes), it shows a prompt when you return:

- **"Was working (e.g., meeting)"** -- keeps the idle time as work time
- **"Was a break"** -- deducts the idle time from your work total

### Overnight Detection

If you leave your Mac on overnight or close the lid and open it the next day, the app automatically:

1. Ends the previous workday at a reasonable time
2. Starts a new workday for today

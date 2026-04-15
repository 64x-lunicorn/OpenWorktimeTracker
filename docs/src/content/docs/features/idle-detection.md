---
title: Idle Detection
description: How OpenWorktimeTracker detects inactivity and lets you decide what to do with it.
---

## How It Works

OpenWorktimeTracker uses `CGEventSource.secondsSinceLastEventType` to detect user inactivity at the hardware level. This detects the absence of keyboard and mouse/trackpad input.

### Detection Loop

1. Every **10 seconds**, the app checks the system idle time
2. When idle time exceeds your configured threshold (default: 5 minutes), the app marks the **idle start time**
3. When user activity resumes, the app calculates the total idle duration
4. A prompt appears asking what to do with the idle time

## The Idle Prompt

When you return from being idle, a dialog appears with two options:

### Same-Day Idle

If the idle period is within the same calendar day:

- **"Was working (e.g., meeting)"** -- the idle time remains counted as work time. Use this when you were in a meeting, on a call, or otherwise working away from your keyboard.
- **"Was a break"** -- the idle time is deducted from your work total and added to your idle pause total.

### Midnight-Crossing Idle

If the idle period spans midnight (e.g., you left your Mac on overnight), the prompt changes:

- Shows that a new workday has been detected
- Lets you set the end time for yesterday's workday
- Automatically starts today's workday

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Idle threshold | 5 minutes | Time of inactivity before triggering the prompt |

You can adjust this in **Settings > General**.

:::tip
Set a higher threshold (e.g., 15 minutes) if you frequently step away briefly and do not want to be prompted each time. Set it lower (e.g., 3 minutes) for more precise tracking.
:::

## Technical Details

- Uses `CGEventSource(.combinedSessionState)` for system-wide idle detection
- Checks keyboard (`.keyboard`) and mouse (`.mouse`) event sources
- Runs on a background timer, separate from the main UI timer
- Idle decisions are persisted in the daily JSON log as an `idleDecisions` array

### Idle Decision Schema

Each idle decision is stored with full context:

```json
{
  "idleStart": "2026-04-15T12:00:00Z",
  "idleEnd": "2026-04-15T12:15:00Z",
  "decision": "pause"
}
```

The `decision` field is either `"work"` (kept as work time) or `"pause"` (deducted).

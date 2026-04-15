---
title: Notifications
description: Configurable threshold notifications to help you manage your work time.
---

## Overview

OpenWorktimeTracker sends native macOS notifications at configurable work time thresholds to help you stay aware of how long you have been working.

## Default Thresholds

| Threshold | Default Time | Message |
|-----------|-------------|---------|
| Normal | 8 hours | "Regulaere Arbeitszeit erreicht" |
| Critical | 9h 50min | "Kritische Arbeitszeit!" |
| Milestone | 10 hours | "Maximum erreicht!" |

## How It Works

- Notifications are triggered based on your **net work time** (after breaks)
- Each threshold fires **only once per day** (tracked in the daily log)
- Notifications use the native `UNUserNotificationCenter` framework
- They appear as standard macOS notifications with sound

## Configuration

You can customize notification thresholds in **Settings > Notifications**:

- Enable or disable all notifications
- Set custom times for each threshold level
- Each threshold can be independently adjusted

:::note
The app needs notification permission from macOS. If you denied it at first launch, go to **System Settings > Notifications > OpenWorktimeTracker** to re-enable.
:::

## Notification Permission

On first launch, the app requests notification permission. If you want to change this later:

1. Open **System Settings**
2. Go to **Notifications**
3. Find **OpenWorktimeTracker**
4. Toggle notifications on or off

---
title: Break Calculation (ArbZG)
description: How OpenWorktimeTracker calculates breaks according to German labor law.
---

## German Labor Law (ArbZG SS4)

The **Arbeitszeitgesetz** (German Working Time Act), Section 4, requires mandatory rest breaks based on total daily work time:

| Work Duration | Required Break |
|--------------|----------------|
| Up to 6 hours | No break required |
| More than 6 hours | At least 30 minutes |
| More than 9 hours | At least 45 minutes |

These breaks do **not** count as work time.

## How It Works in OWT

OpenWorktimeTracker implements this as **auto-break** --- an automatic deduction from your gross work time:

```
Net Work Time = Gross Time - Auto Break - Manual Pauses
```

### Auto-Break Logic

The auto-break is calculated based on your **work time before auto-break** (gross time minus manual pauses):

1. If `workTimeBeforeAutoBreak > 9h`: auto-break = `max(0, 45min - manualPause)`
2. If `workTimeBeforeAutoBreak > 6h`: auto-break = `max(0, 30min - manualPause)`
3. Otherwise: auto-break = `0`

### Manual Pauses Count

If you manually pause the timer or classify idle time as a break, those pauses count **against** the required break. For example:

- You worked 7 hours gross, with a 20-minute manual pause
- Required break: 30 minutes
- Auto-break: `30 - 20 = 10 minutes`
- Net work time: `7h - 10min - 20min = 6h 30min`

If your manual pauses already exceed the required break, no additional auto-break is applied.

## Configuration

You can customize the break thresholds in **Settings > Breaks**:

| Setting | Default | Description |
|---------|---------|-------------|
| First break threshold | 6 hours | When the first break kicks in |
| First break duration | 30 minutes | Duration of the first break tier |
| Second break threshold | 9 hours | When the extended break kicks in |
| Second break duration | 45 minutes | Duration of the second break tier |

:::caution
While the thresholds are configurable, the defaults are based on German law. Changing them may put you out of compliance with ArbZG SS4.
:::

## Examples

### Scenario 1: Standard 8-hour day

- Gross time: 8h 30min
- Manual pauses: 0
- Auto-break: 30min (because > 6h)
- **Net work time: 8h 00min**

### Scenario 2: Long day with lunch break

- Gross time: 10h 00min
- Manual pause (lunch): 45min
- Auto-break: `max(0, 45min - 45min)` = 0min
- **Net work time: 9h 15min**

### Scenario 3: Short day

- Gross time: 5h 30min
- Manual pauses: 0
- Auto-break: 0 (under 6h)
- **Net work time: 5h 30min**

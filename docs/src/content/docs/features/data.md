---
title: Data & Export
description: How OpenWorktimeTracker stores and exports your work time data.
---

## Storage Location

Daily work logs are stored as JSON files in:

```
~/Library/Application Support/OpenWorktimeTracker/logs/
```

Each file is named by date: `YYYY-MM-DD.json` (e.g., `2026-04-15.json`).

## JSON Format

Each daily log file contains a single `TimeEntry` object:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2026-04-15",
  "startTime": "2026-04-15T08:03:00Z",
  "endTime": "2026-04-15T17:15:00Z",
  "status": "ended",
  "manualPauseSeconds": 900,
  "idleDecisions": [
    {
      "idleStart": "2026-04-15T12:00:00Z",
      "idleEnd": "2026-04-15T12:15:00Z",
      "decision": "pause"
    }
  ],
  "notifiedThresholds": ["normal"],
  "note": "Focused on project X today"
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier for the entry |
| `date` | String | Calendar date (YYYY-MM-DD) |
| `startTime` | ISO 8601 | When the workday started |
| `endTime` | ISO 8601? | When the workday ended (null if still running) |
| `status` | String | `notStarted`, `running`, `paused`, or `ended` |
| `manualPauseSeconds` | Double | Total manual pause time in seconds |
| `idleDecisions` | Array | List of idle periods and their classification |
| `notifiedThresholds` | Array | Which notification thresholds have fired |
| `note` | String | Optional daily note |

## CSV Export

You can export your work history as CSV from the popover menu (**...** > **Export CSV**). The CSV includes:

- Date
- Start time
- End time
- Gross time
- Net time
- Break time
- Manual pause
- Note

## Data Privacy

- All data is stored **locally** on your Mac
- No data is sent to any server
- No analytics, no telemetry
- You own your data completely

## Backup

Since data is plain JSON files, you can back them up with any file backup tool:

```bash
# Manual backup
cp -r ~/Library/Application\ Support/OpenWorktimeTracker/logs/ ~/Desktop/owt-backup/

# Or include in Time Machine (happens automatically)
```

## Custom Storage Location

In **Settings > Data**, you can choose a custom storage directory. This is useful if you want to store logs in a synced folder (e.g., iCloud Drive or Dropbox).

The app uses macOS security-scoped bookmarks to remember access to custom directories across launches.

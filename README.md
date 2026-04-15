<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-AGPL--3.0-blue" alt="AGPL-3.0 License">
  <img src="https://img.shields.io/github/v/release/64x-lunicorn/OpenWorktimeTracker?include_prereleases" alt="Release">
  <img src="https://img.shields.io/github/actions/workflow/status/64x-lunicorn/OpenWorktimeTracker/build.yml?label=build" alt="Build">
</p>

# OpenWorktimeTracker

A native macOS menu bar app that **automatically tracks your daily working hours** — silently, smartly, and beautifully.

No Dock icon. No manual start. Just open your Mac and your workday begins.

## Features

- **Auto-Start** — Launches at login, starts tracking immediately
- **Smart Day Detection** — Detects new workdays automatically (overnight, sleep/wake, restart)
- **ArbZG-Compliant Breaks** — Automatic break calculation per German labor law (§4 ArbZG)
- **Threshold Notifications** — Alerts at configurable limits (e.g., 8h normal, 10h critical)
- **Idle Detection** — Detects inactivity and asks: "Was that a meeting or a break?"
- **Screen Lock Detection** — Recognizes lock/unlock as idle periods
- **Live Menu Bar** — Shows net work time, color-coded by threshold, animated while running
- **7-Day History + Stats** — Weekly bar chart and week/month summary with overtime tracking
- **Manual Time Editing** — Adjust start/end time directly in the popover
- **Global Shortcuts** — Ctrl+Option+P (pause/resume), Ctrl+Option+E (end day)
- **iCloud Sync** — Sync daily logs to iCloud Drive across devices
- **macOS Widgets** — Small and medium widgets showing current work time
- **Daily JSON Logs** — Transparent, exportable, one file per day
- **Sparkle Auto-Updates** — Seamless updates via GitHub Releases
- **Ethereal Design** — Glassmorphism, tonal depth, adaptive light/dark mode

---

## Architecture

### System Overview

```mermaid
graph TB
    subgraph "macOS Menu Bar"
        MB[Menu Bar Icon<br/>Shows Net Time]
    end

    subgraph "App Layer"
        APP["@main<br/>OpenWorktimeTrackerApp"]
        AD[AppDelegate<br/>Sleep/Wake · Sparkle]
    end

    subgraph "Views"
        MBV[MenuBarView<br/>Popover]
        SV[SettingsView<br/>Window]
        IPV[IdlePromptView<br/>Sheet]
    end

    subgraph "Core Services"
        WM["WorkdayManager<br/>@Observable State Machine"]
        WD[WorkdayDetector<br/>New Day Logic]
        BC[BreakCalculator<br/>ArbZG §4]
        ID[IdleDetector<br/>CGEventSource]
        NM[NotificationManager<br/>UNUserNotification]
        PM[PersistenceManager<br/>JSON Files]
    end

    subgraph "Data"
        TE[TimeEntry<br/>Codable Model]
        UD["UserDefaults<br/>@AppStorage"]
        FS["~/Library/App Support/<br/>OpenWorktimeTracker/logs/"]
    end

    MB --> MBV
    APP --> AD
    APP --> MBV
    APP --> SV
    MBV --> WM
    SV --> UD
    MBV --> IPV
    WM --> WD
    WM --> BC
    WM --> ID
    WM --> NM
    WM --> PM
    PM --> TE
    PM --> FS
    ID --> IPV
    WD --> IPV
```

### State Machine

```mermaid
stateDiagram-v2
    [*] --> NotStarted: App Launch

    NotStarted --> Running: Auto-start<br/>(new day detected)
    NotStarted --> Running: Resume<br/>(existing entry today)

    Running --> Paused: User clicks Pause
    Running --> Paused: Idle detected<br/>(user chose "was break")
    Running --> Ended: User clicks End Day

    Paused --> Running: User clicks Resume
    Paused --> Ended: User clicks End Day

    Ended --> [*]: Day complete

    Ended --> Running: New day detected<br/>(auto-end previous,<br/>auto-start new)
```

### Workday Detection Flow

```mermaid
flowchart TD
    START([App Launch / Wake / Timer Tick]) --> CHECK{Today's entry<br/>exists?}

    CHECK -->|No| PREV{Previous day<br/>still running?}
    CHECK -->|Yes, Running| RESUME[Resume tracking]
    CHECK -->|Yes, Paused| RESUME_P[Resume paused]
    CHECK -->|Yes, Ended| DONE[Show completed]

    PREV -->|No| AUTO[Auto-start new day]
    PREV -->|Yes| PROMPT[Show IdlePrompt:<br/>'New workday detected!<br/>End yesterday at ___?']

    PROMPT --> |User confirms| END_PREV[End previous day<br/>at selected time]
    END_PREV --> AUTO

    AUTO --> RUNNING((Running))
    RESUME --> RUNNING
    RESUME_P --> PAUSED((Paused))

    style PROMPT fill:#ff9800,color:#000
    style AUTO fill:#4caf50,color:#fff
    style RUNNING fill:#2196f3,color:#fff
```

### Idle Detection Flow

```mermaid
flowchart TD
    TICK[Every 30s: Check Idle] --> IDLE{Idle > threshold?}

    IDLE -->|No| TICK
    IDLE -->|Yes| MARK[Mark idle start time]

    MARK --> WAIT[Wait for activity]
    WAIT --> ACTIVE[User returns]

    ACTIVE --> SPAN{Idle spans<br/>midnight?}

    SPAN -->|Same day| PROMPT1["Show prompt:<br/>'Du warst X Min inaktiv.<br/>Arbeitszeit oder Pause?'"]
    SPAN -->|Crosses midnight| PROMPT2["Show prompt:<br/>'Neuer Arbeitstag!<br/>Gestern um ___ beenden?<br/>Heute jetzt starten?'"]

    PROMPT1 -->|Was working| KEEP[Keep as work time]
    PROMPT1 -->|Was break| DEDUCT[Deduct from work time]

    PROMPT2 -->|Confirm| NEW[End yesterday,<br/>start today]

    style PROMPT1 fill:#ff9800,color:#000
    style PROMPT2 fill:#f44336,color:#fff
```

### Break Calculation (ArbZG §4)

```mermaid
flowchart LR
    NET[Net Work Time] --> C1{> 6 hours?}
    C1 -->|No| B0[No auto break]
    C1 -->|Yes| C2{> 9 hours?}
    C2 -->|No| B30[30 min break]
    C2 -->|Yes| B45[45 min break]

    B30 --> CALC["Auto Break =<br/>max(0, required - manual pause)"]
    B45 --> CALC

    CALC --> RESULT["Display Time =<br/>Gross − Auto Break − Manual Pause"]

    style B30 fill:#ff9800,color:#000
    style B45 fill:#f44336,color:#fff
```

### CI/CD Pipeline

```mermaid
flowchart LR
    subgraph "PR Workflow"
        PR[Pull Request] --> BUILD[Xcode Build]
        BUILD --> TEST[Run Tests]
        TEST --> LINT[SwiftLint]
    end

    subgraph "Release Workflow"
        TAG["Push Tag v*"] --> RBUILD[Xcode Build<br/>Release Config]
        RBUILD --> SIGN[Code Sign<br/>Developer ID]
        SIGN --> NOTARIZE[Apple Notarization]
        NOTARIZE --> STAPLE[Staple Ticket]
        STAPLE --> DMG[Create DMG]
        DMG --> APPCAST[Generate<br/>Sparkle Appcast]
        APPCAST --> RELEASE[GitHub Release<br/>Upload Assets]
    end

    style TAG fill:#4caf50,color:#fff
    style RELEASE fill:#2196f3,color:#fff
```

---

## Installation

### Download (Recommended)
1. Go to [Releases](../../releases)
2. Download `OpenWorktimeTracker.dmg`
3. Drag to Applications
4. Launch — it appears in your menu bar

The app auto-updates via Sparkle when new versions are available.

### Build from Source
```bash
# Prerequisites
brew install xcodegen swiftlint

# Clone & build
git clone https://github.com/64x-lunicorn/OpenWorktimeTracker.git
cd OpenWorktimeTracker
make build
```

---

## How It Works

1. **Open your Mac** → App starts automatically (Login Item)
2. **Work normally** → Timer runs in the menu bar showing your net time
3. **Take breaks** → Idle detection asks if inactive time was a break or meeting
4. **Get notified** → Alerts at your configured thresholds (e.g., 8h, 10h)
5. **Day ends** → Click "End Day" or let it auto-detect overnight
6. **Next morning** → New workday starts automatically

### Menu Bar States

| State | Display | Color |
|-------|---------|-------|
| Working < 8h | `07:41` | Default |
| Working > Orange threshold | `08:15` | Orange |
| Working > Red threshold | `09:45` | Red |
| Paused | `[paused] 07:41` | Default |
| Day ended | `[done] 08:15` | Default |

---

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Orange Threshold | 8h | Menu bar turns orange |
| Red Threshold | 9.5h | Menu bar turns red |
| Break after >6h | 30 min | ArbZG auto-break |
| Break after >9h | 45 min | ArbZG auto-break |
| Normal Notification | 8h | "Regular hours reached" |
| Critical Notification | 9.83h | "Time to go!" |
| Milestone Notification | 10h | "Maximum reached!" |
| Idle Threshold | 5 min | Time before idle prompt |
| Launch at Login | On | Auto-start with macOS |
| iCloud Sync | Off | Sync logs to iCloud Drive |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+Option+P | Pause / Resume |
| Ctrl+Option+E | End Day |

---

## Data Storage

Daily logs stored as JSON in:
```
~/Library/Application Support/OpenWorktimeTracker/logs/2026-04-15.json
```

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2026-04-15",
  "startTime": "2026-04-15T08:03:00Z",
  "endTime": null,
  "status": "running",
  "manualPauseSeconds": 0,
  "idleDecisions": [
    {
      "idleStart": "2026-04-15T12:00:00Z",
      "idleEnd": "2026-04-15T12:15:00Z",
      "decision": "pause"
    }
  ],
  "notifiedThresholds": ["normal"],
  "note": ""
}
```

---

## Tech Stack

- **SwiftUI** + AppKit hybrid — `MenuBarExtra` for menu bar, native macOS feel
- **`@Observable`** — Modern Swift 5.9 state management (no ObservableObject)
- **`SMAppService`** — Native Login Item (no helper app needed)
- **`CGEventSource`** — Hardware-level idle detection
- **`UNUserNotificationCenter`** — Native macOS notifications
- **Sparkle 2** — EdDSA-signed auto-updates
- **XcodeGen** — Xcode project from YAML spec
- **GitHub Actions** — CI/CD with code signing & notarization

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

[AGPL-3.0](LICENSE) — Free to use, modify, and distribute. Any modified version must also be open source under the same license.

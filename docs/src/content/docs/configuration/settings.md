---
title: Settings
description: All configurable options in OpenWorktimeTracker.
---

## Accessing Settings

Open Settings from the popover menu (**...** > **Settings**) or use the keyboard shortcut **Cmd + ,** when the popover is open.

Settings are organized into three tabs.

## General

| Setting | Default | Description |
|---------|---------|-------------|
| Launch at Login | On | Auto-start the app when you log in to macOS |
| Idle Threshold | 5 minutes | How long before inactivity triggers the idle prompt |

## Notifications

| Setting | Default | Description |
|---------|---------|-------------|
| Enable Notifications | On | Master toggle for all notifications |
| Normal Threshold | 8 hours | "Regular hours reached" notification |
| Critical Threshold | 9h 50min | "Time to go!" notification |
| Milestone Threshold | 10 hours | "Maximum reached!" notification |

## Breaks

| Setting | Default | Description |
|---------|---------|-------------|
| Break Threshold 1 | 6 hours | Work time before first break applies |
| Break Duration 1 | 30 minutes | Duration of the first break tier |
| Break Threshold 2 | 9 hours | Work time before extended break applies |
| Break Duration 2 | 45 minutes | Duration of the extended break tier |

:::caution
The default break values follow German labor law (ArbZG SS4). Changing them may affect legal compliance.
:::

## Appearance

| Setting | Default | Description |
|---------|---------|-------------|
| Orange Threshold | 8 hours | Menu bar text turns orange |
| Red Threshold | 9.5 hours | Menu bar text turns red |

## Data

| Setting | Default | Description |
|---------|---------|-------------|
| Storage Location | App Support | Where daily JSON logs are saved |
| Custom Directory | -- | Choose a custom folder for logs |

## Where Settings Are Stored

Settings use `@AppStorage` (backed by `UserDefaults`). They are stored in the app's preferences plist:

```
~/Library/Preferences/com.lunicorn-lab.OpenWorktimeTracker.plist
```

Settings sync with iCloud if you have iCloud preferences syncing enabled in macOS.

---
title: Installation
description: How to install OpenWorktimeTracker on your Mac.
---

## System Requirements

- **macOS 14.0+** (Sonoma or later)
- Apple Silicon or Intel Mac

## Download (Recommended)

1. Go to the [latest Release on GitHub](https://github.com/64x-lunicorn/OpenWorktimeTracker/releases)
2. Download `OpenWorktimeTracker.dmg`
3. Open the DMG and drag OpenWorktimeTracker to your **Applications** folder
4. Launch the app -- it appears in your **menu bar** (not the Dock)

:::tip
The app auto-updates via Sparkle when new versions are available. You only need to download manually once.
:::

## Build from Source

If you prefer to build from source or want to contribute:

### Prerequisites

```bash
brew install xcodegen swiftlint
```

- **Xcode 16+** (with macOS 14 SDK)
- **XcodeGen** -- generates the Xcode project from `project.yml`
- **SwiftLint** -- code style linting

### Clone and Build

```bash
git clone https://github.com/64x-lunicorn/OpenWorktimeTracker.git
cd OpenWorktimeTracker
make build
```

### Available Make Commands

| Command | Description |
|---------|-------------|
| `make build` | Build release configuration |
| `make test` | Run all unit tests |
| `make lint` | Run SwiftLint |
| `make generate` | Regenerate Xcode project from `project.yml` |
| `make clean` | Clean build artifacts |

## First Launch

After installation, OpenWorktimeTracker will:

1. Appear as a clock icon in your menu bar
2. Ask for notification permission (recommended: allow)
3. Start tracking your workday automatically

:::note
The app runs entirely in the menu bar. There is no Dock icon and no main window. Click the menu bar icon to open the popover.
:::

## Launch at Login

By default, the app registers itself as a Login Item via `SMAppService`. You can toggle this in **Settings > General > Launch at Login**.

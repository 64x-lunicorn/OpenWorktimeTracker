---
title: Build from Source
description: How to set up a development environment for OpenWorktimeTracker.
---

## Prerequisites

- **macOS 14.0+** (Sonoma)
- **Xcode 16+** with macOS 14 SDK
- **Homebrew** (for installing tools)

### Install Build Tools

```bash
brew install xcodegen swiftlint
```

## Clone and Build

```bash
git clone https://github.com/64x-lunicorn/OpenWorktimeTracker.git
cd OpenWorktimeTracker
```

### Generate Xcode Project

The Xcode project is generated from `project.yml` using XcodeGen:

```bash
xcodegen generate
```

This creates `OpenWorktimeTracker.xcodeproj` from the YAML specification.

### Open in Xcode

```bash
open OpenWorktimeTracker.xcodeproj
```

### Build via Command Line

```bash
make build
```

## Make Targets

| Command | Description |
|---------|-------------|
| `make build` | Build release configuration |
| `make test` | Run all unit tests |
| `make lint` | Run SwiftLint |
| `make generate` | Regenerate Xcode project |
| `make clean` | Clean build artifacts |

## Running Tests

```bash
make test
```

The test suite includes:
- **BreakCalculatorTests** -- ArbZG break logic edge cases
- **WorkdayDetectorTests** -- New day detection scenarios
- **PersistenceManagerTests** -- JSON round-trip and file I/O
- **TimeEntryTests** -- Model encoding/decoding

## Project Configuration

The project is defined in `project.yml`:
- **Deployment target**: macOS 14.0
- **Swift version**: 5.9
- **Dependencies**: Sparkle 2 (via SPM)
- **Info.plist**: Custom at `OpenWorktimeTracker/Resources/Info.plist`
- **Entitlements**: `OpenWorktimeTracker/Resources/OpenWorktimeTracker.entitlements`

## Debugging

For debugging, build in Debug configuration in Xcode. The app will:
- Run from Xcode's build directory (not Applications)
- Not register as a Login Item (unless you check the box in Settings)
- Store data in the same Application Support directory as the release build

:::tip
Since the app is a menu bar app (`LSUIElement = YES`), it will not appear in the Dock. Look for it in the menu bar after running.
:::

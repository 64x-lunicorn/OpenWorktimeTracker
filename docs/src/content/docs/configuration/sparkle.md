---
title: Auto-Updates (Sparkle)
description: How OpenWorktimeTracker handles automatic updates via Sparkle.
---

## Overview

OpenWorktimeTracker uses [Sparkle 2](https://sparkle-project.org/) for automatic updates. Sparkle is the standard update framework for macOS apps distributed outside the Mac App Store.

## How It Works

1. The app periodically checks an **appcast** (an XML feed) hosted on GitHub Pages
2. If a new version is available, a native macOS update dialog appears
3. Updates are signed with **EdDSA** (Ed25519) for security
4. The user can choose to install now or later

## Appcast URL

The appcast is hosted at:

```
https://64x-lunicorn.github.io/OpenWorktimeTracker/appcast.xml
```

This URL is configured in `Info.plist` under the `SUFeedURL` key.

## Setting Up Sparkle (For Maintainers)

### 1. Generate EdDSA Keys

```bash
# Download Sparkle tools
curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/2.6.0/Sparkle-2.6.0.tar.xz" | tar xJ

# Generate key pair
./bin/generate_keys
```

### 2. Configure Keys

- **Public key**: Add to `Info.plist` under `SUPublicEDKey`
- **Private key**: Store as GitHub Secret `SPARKLE_PRIVATE_KEY`

### 3. GitHub Pages Setup

The release workflow automatically:
1. Builds and signs the app
2. Creates a DMG
3. Generates an updated `appcast.xml` using `generate_appcast`
4. Publishes to GitHub Pages

### 4. Enable Auto-Updates

In `AppDelegate.swift`, set `startingUpdater: true` once the appcast and keys are configured:

```swift
updaterController = SPUStandardUpdaterController(
    startingUpdater: true,   // Enable auto-updates
    updaterDelegate: nil,
    userDriverDelegate: nil
)
```

:::note
Auto-updates are currently disabled (`startingUpdater: false`) until the Sparkle keys and appcast are set up. The app will work fine without updates -- you just need to download new versions manually.
:::

## Security

Sparkle 2 uses EdDSA (Ed25519) signatures to verify update authenticity:
- Each release is signed with the private key during CI/CD
- The app verifies signatures using the embedded public key
- Tampered updates are rejected automatically

This ensures that only updates signed by the project maintainer are installed.

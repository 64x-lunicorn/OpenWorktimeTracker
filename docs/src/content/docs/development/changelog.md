---
title: Changelog
description: All notable changes to OpenWorktimeTracker.
---

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release
- Menu bar app with live net work time display
- Automatic workday detection (new day, overnight, sleep/wake)
- ArbZG-compliant auto-break calculation (configurable thresholds)
- Idle detection with user prompt (work time vs. break)
- Threshold notifications (normal, critical, milestone)
- Daily JSON log files in Application Support
- Settings window (appearance, breaks, notifications, startup)
- Launch at Login via SMAppService
- Sparkle auto-updates (framework integrated, awaiting key setup)
- CSV export
- GitHub Actions CI/CD with code signing and notarization
- Ethereal Chronometer design system (glassmorphism, adaptive colors)
- 32 unit tests (BreakCalculator, WorkdayDetector, PersistenceManager, TimeEntry)
- Documentation website (Starlight/Astro)

# Next Steps & Roadmap

## Testing Checklist

Test the app for a few days and observe the following:

- [ ] **New day transition** -- open Mac in the morning, does a new day start automatically?
- [ ] **Sleep/Wake** -- close lid, reopen, is the timer correct?
- [ ] **Idle prompt** -- stay inactive for 5 min, does the floating dialog appear?
- [ ] **Notifications** -- do they fire at 8h / 9.83h / 10h?
- [ ] **Menu bar color** -- orange at 8h, red at 9.5h?
- [ ] **JSON logs** -- check `~/Library/Application Support/OpenWorktimeTracker/logs/`
- [ ] **Settings** -- are changes applied immediately?
- [ ] **App restart** -- quit and relaunch, does today's entry resume?
- [ ] **CSV export** -- does it work via the `...` menu?
- [ ] **Pause/Resume** -- is manual pause calculated correctly?
- [ ] **Manual time edit** -- can start/end time be adjusted in the popover?
- [ ] **7-day history** -- is the weekly overview visible in the popover?

---

## Priority 1 -- Before Release

- [x] App icon (indigo clock with play indicator)
- [x] `SUFeedURL` in Info.plist set to GitHub Pages URL
- [x] GitHub repo URL in README.md (64x-lunicorn)
- [x] Generate Sparkle EdDSA keys and set `SUPublicEDKey`
- [x] License: AGPL-3.0
- [x] Last 7 days overview in popover
- [x] Show manual pause duration in popover
- [x] Estimated end time for 8h target
- [x] Sound feedback on notifications
- [x] Manual start/end time editing
- [x] EN/DE localization (Localizable.strings)

---

## Priority 2 -- Quality of Life

- [x] Global keyboard shortcuts (Ctrl+Option+P pause, Ctrl+Option+E end day)
- [x] Weekly/monthly summary statistics
- [x] iCloud sync for logs
- [x] Widgets (macOS Widget API) -- requires Developer Team signing for WidgetKit
- [x] Menu bar icon animation while running
- [x] Screen lock/unlock detection (idle prompt + state save)

---

## Priority 3 -- Before v1.0 Release

- [x] Enable Sparkle auto-updates (`startingUpdater: true` in AppDelegate) + Appcast on GitHub Pages
- [x] Configure GitHub Secrets:
  - `DEVELOPER_ID_CERTIFICATE_P12` -- Base64-encoded .p12 certificate
  - `CERTIFICATE_PASSWORD` -- Password for .p12
  - `APPLE_ID` -- Apple ID email
  - `APPLE_TEAM_ID` -- Team ID from Developer Portal
  - `NOTARIZATION_PASSWORD` -- App-specific Password
  - `SPARKLE_PRIVATE_KEY` -- EdDSA Private Key for Sparkle
- [ ] Run manual testing checklist (see above)
- [ ] Push first release tag (`git tag v0.1.0 && git push --tags`)

---

## Sparkle Key Setup

```bash
# Generate Sparkle EdDSA keys (one-time)
curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/2.6.0/Sparkle-2.6.0.tar.xz" | tar xJ
./bin/generate_keys
# Add public key to Info.plist under SUPublicEDKey
# Store private key as GitHub Secret SPARKLE_PRIVATE_KEY
```

## First Release

```bash
git tag v0.1.0
git push --tags
# GitHub Actions will build, sign, notarize, and create DMG release automatically
```

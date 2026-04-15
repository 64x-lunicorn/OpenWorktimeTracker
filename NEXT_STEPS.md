# Next Steps & Roadmap

## Testing Checklist (vor Git Push)

Teste die App ein paar Tage und beobachte folgendes:

- [ ] **Neuer-Tag-Übergang** — Mac morgens aufklappen → startet neuer Tag automatisch?
- [ ] **Sleep/Wake** — Laptop zuklappen, wieder öffnen → Timer korrekt?
- [ ] **Idle-Prompt** — 5 Min nichts tun → kommt der Dialog? (Standard: 5 Min)
- [ ] **Notifications** — Kommen bei 8h / 9.83h / 10h?
- [ ] **Menu Bar Farbe** — Wechselt bei 8h (orange) und 9.5h (rot)?
- [ ] **JSON-Logs** — Prüfe `~/Library/Application Support/OpenWorktimeTracker/logs/`
- [ ] **Settings** — Werden Änderungen übernommen?
- [ ] **App-Neustart** — Beendet + neu gestartet → heutiger Tag wird fortgesetzt?
- [ ] **CSV Export** — Funktioniert der Export über das `···` Menü?
- [ ] **Pause/Resume** — Wird die manuelle Pause korrekt berechnet?

---

## Priorität 1 — Vor Git Push

- [ ] App Icon erstellen (aktuell: generisches leeres Icon)
- [ ] `SUFeedURL` in Info.plist auf echte GitHub URL setzen
- [x] GitHub Repo URL in README.md ersetzen (64x-lunicorn)
- [ ] Sparkle EdDSA Keys generieren und `SUPublicEDKey` setzen
- [x] Lizenz: AGPL-3.0

---

## Priorität 2 — Quality of Life

- [ ] Globale Keyboard Shortcuts (z.B. `⌘⇧P` für Pause)
- [ ] Letzte 7 Tage Übersicht im Popover
- [ ] Manual Pause Dauer anzeigen im Popover
- [ ] "Heute beenden um X Uhr für 8h" Schätzung anzeigen
- [ ] Sound-Feedback bei Notifications
- [ ] Lokalisierung DE/EN

---

## Priorität 3 — Vor v1.0 Release

- [ ] Sparkle aktivieren (`startingUpdater: true` in AppDelegate) + Appcast auf GitHub Pages
- [ ] GitHub Secrets einrichten:
  - `DEVELOPER_ID_CERTIFICATE_P12` — Base64-encoded .p12 Zertifikat
  - `CERTIFICATE_PASSWORD` — Passwort für .p12
  - `APPLE_ID` — Apple ID Email
  - `APPLE_TEAM_ID` — Team ID aus Developer Portal
  - `NOTARIZATION_PASSWORD` — App-specific Password
  - `SPARKLE_PRIVATE_KEY` — EdDSA Private Key für Sparkle
- [ ] Ersten Release-Tag pushen (`git tag v0.1.0 && git push --tags`)
- [ ] Homebrew Cask Formula vorbereiten
- [ ] Screenshots für README (Light + Dark)

---

## Git Push Anleitung

```bash
cd ~/Documents/dev/openWorktimeTracker

# Option A: Mit GitHub CLI
gh repo create OpenWorktimeTracker --public --source=. --push

# Option B: Manuell
git add -A
git commit -m "feat: initial release — menu bar worktime tracker"
git remote add origin git@github.com:DEIN-USERNAME/OpenWorktimeTracker.git
git push -u origin main
```

## Sparkle Keys generieren

```bash
# Sparkle EdDSA Keys generieren (einmalig)
# 1. Download Sparkle Tools
curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/2.6.0/Sparkle-2.6.0.tar.xz" | tar xJ

# 2. Keys generieren
./bin/generate_keys

# 3. Public Key in Info.plist unter SUPublicEDKey eintragen
# 4. Private Key als GitHub Secret SPARKLE_PRIVATE_KEY speichern
```

## Erster Release

```bash
# Version setzen
git tag v0.1.0
git push --tags
# → GitHub Actions baut automatisch, signiert, notarisiert und erstellt DMG Release
```

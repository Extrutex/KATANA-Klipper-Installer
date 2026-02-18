# KATANAOS v2.2 — Changelog

## Menü: 6 statt 16 Punkte
```
[1] QUICK START    [2] FORGE    [3] EXTRAS
[4] UPDATE         [5] DIAGNOSE [6] SETTINGS
```

## Neu
- **Quick Start** mit Profilen (minimal/standard/power)
- **Forge:** `lsusb` Auto-Detection + DFU Auto-Flash
- **Update:** Auto-Branch-Erkennung (master/main)
- **Engine-Erkennung:** Klipper/Kalico/RatOS (Verzeichnis + Symlink)
- **PolicyKit:** Alle 8 Moonraker-Actions, modern + legacy Format
- **Post-Install Summary** mit Checkmarks

## Bugfixes
- `apt-get >/dev/null` schluckte sudo-Prompt
- `make flash` ohne `FLASH_DEVICE`
- DFU-Detach-Fehler fälschlich als Fehler gemeldet
- Update: `origin/main` statt `origin/master`
- KlipperScreen: Endlosrekursion im Dispatcher
- Mainsail Update Manager: Args falsche Reihenfolge

## Entfernt (war nicht funktional)
UFW, SSH Hardening, Printer Config Wizard, Auto-Restart, OctoPrint, Restic

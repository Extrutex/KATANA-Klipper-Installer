# ⚔️ KATANAOS v2.2 - Changelog

## Komplett überarbeitetes System

v2.2 ist ein Ground-Up Rewrite mit Fokus auf **Stabilität und echte Funktionalität**.

---

## Neues Menü-System (6 Punkte statt 16)

```
╔══════════════════════════════════════════════════════════════════════╗
║  [1]  QUICK START         Auto-Pilot Installation                  ║
║  [2]  FORGE               Build & Flash MCU Firmware               ║
║  [3]  EXTRAS              Vision / Probes / System / Tools         ║
║  [4]  UPDATE              Klipper & Moonraker                      ║
║  [5]  DIAGNOSE            Service Status / Logs / Repair           ║
║  [6]  SETTINGS            Profile / Engine / CAN / Uninstall       ║
╚══════════════════════════════════════════════════════════════════════╝
```

> Aufgeräumt: Alles logisch gruppiert statt 16 einzelne Punkte.

---

## Was ist neu in v2.2

### ✅ Quick Start mit Profilen
- **Auto-Pilot** Installation: 1 Tastendruck → kompletter Stack
- Profile: `minimal` / `standard` / `power`
- Post-Install Summary mit Checkmarks

### ✅ Forge komplett überarbeitet
- Nutzt `menuconfig` direkt → **jedes Board unterstützt**
- USB-Erkennung via `lsusb`:
  - `0483:df11` → STM32 DFU (auto-flash)
  - `1d50:614e` → Klipper USB (bereits geflasht)
  - `1d50:6177` → Katapult Bootloader
  - `/dev/serial/by-id/` → USB Serial
- DFU-Detach-Fehler automatisch als Erfolg erkannt
- Linux Host MCU vollautomatisch

### ✅ Update Manager
- Auto-Erkennung des Git-Branch (`master` vs `main`)
- Klipper und Moonraker einzeln oder zusammen
- Moonraker nutzt korrektes virtualenv pip

### ✅ Engine-Erkennung
- Erkennt Klipper / Kalico / RatOS
- Prüft Verzeichnis UND Symlink
- Status-Anzeige im Hauptmenü

### ✅ Extras konsolidiert
Alles unter einem Dach:
- Vision (Crowsnest, KlipperScreen)
- Smart Probes (Beacon, Cartographer, BTT Eddy)
- Printing (ShakeTune, KATANA-FLOW, Multi-Material)
- System (Backup, Restore, Log2Ram)
- Web UI (Mainsail, Fluidd)

### ✅ Backup & Restore
- ZIP-Backups mit automatischer Rotation (max 5)
- Git Push für versionierte Config-Backups
- Restore mit Service-Stop/Start und Permissions-Fix

### ✅ Diagnose
- Service Status (systemctl)
- Log Viewer (Klipper, Moonraker, dmesg)
- Repair-Menü (Restart, Validate)
- Emergency (Reinstall, Uninstall)

### ✅ PolicyKit
- Vollständige Rules für Moonraker
- Modern (.rules JS) + Legacy (.pkla) Format
- Alle 8 erforderlichen Actions

---

## Was entfernt wurde (war nicht funktional)

| Feature | Grund |
|---|---|
| UFW Firewall (Menü 11) | War nicht implementiert |
| SSH Hardening | War nicht implementiert |
| Printer Config Wizard (Menü 14) | War nicht implementiert |
| Auto-Restart (Menü 15) | War nicht implementiert |
| OctoPrint (Menü 16) | War nicht implementiert |
| Restic Backup | War nicht implementiert |
| HORIZON UI | Separates Projekt |

> **Philosophie:** Lieber 6 Punkte die funktionieren als 16 die es nicht tun.

---

## Bugfixes in v2.2

1. `apt-get > /dev/null` schluckte Passwort-Prompt → Fix: sichtbare Ausgabe
2. Forge: `FLASH_DEVICE` fehlte bei `make flash` → Fix: auto-detect
3. Forge: DFU-Detach-Fehler als Fehler gemeldet → Fix: Output prüfen
4. Update: `origin/main` statt `origin/master` → Fix: auto-detect Branch
5. Engine-Erkennung: nur Symlinks geprüft → Fix: auch reguläre Verzeichnisse
6. Mainsail Update Manager: Args in falscher Reihenfolge → Fix: korrektes Mapping
7. KlipperScreen: Endlosrekursion im Dispatcher → Fix: Funktion umbenannt
8. Crowsnest: kaputtes `source` beim Laden → Fix: unnötige Abhängigkeit entfernt

---

## Upgrade von v2.1

```bash
cd ~/KATANA-Klipper-Installer
git pull
./katanaos.sh
```

---

> **KATANAOS v2.2** — Weniger Menü, mehr Funktion.

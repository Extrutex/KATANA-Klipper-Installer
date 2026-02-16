# ⚔️ KATANAOS v2.1 - Was ist neu?

## Komplett überarbeitetes Menü-System

```
┌──────────────────────────────────────────────────────────────────┐
│ SYSTEM STATUS                                                    │
├──────────────────────────────────────────────────────────────────┤
│ ● Klipper       : ONLINE    3D Printer Firmware                │
│ ● Moonraker     : ONLINE    API Server                         │
├──────────────────────────────────────────────────────────────────┤
│ >> WEB INTERFACES                                              │
├──────────────────────────────────────────────────────────────────┤
│ ● Mainsail      : INSTALLED                                     │
│ ○ Fluidd        : NOT INSTALLED                                │
│ ○ HORIZON       : NOT INSTALLED                                │
├──────────────────────────────────────────────────────────────────┤
│ >> HARDWARE & EXTRAS                                           │
├──────────────────────────────────────────────────────────────────┤
│ ● Crowsnest     : INSTALLED                                     │
│ ○ KlipperScreen: NOT INSTALLED                                │
│ ○ Happy Hare    : NOT INSTALLED                                │
│ ○ Smart Probe   : NOT INSTALLED                                │
├──────────────────────────────────────────────────────────────────┤
│ COMMAND DECK                                                    │
├──────────────────────────────────────────────────────────────────┤
│ [1] Full Install       Klipper + Moonraker + UI                │
│ [2] Core Firmware     Klipper / Kalico / RatOS                 │
│ [3] Web UI            Mainsail / Fluidd / HORIZON               │
│ [4] Vision Stack      Crowsnest / KlipperScreen                │
│ [5] The Forge         Flash MCU / CAN-Bus                      │
│ [6] Engine Switch     Current: KLIPPER                          │
│ [7] Update           Klipper & Moonraker                       │
│ [8] Diagnostics       Log Analysis & Repair                    │
│ [9] KATANA FLOW      Smart Purge / Adaptive Mesh               │
│ [10] Hardware         Happy Hare / Smart Probe                 │
│ [11] Security         Firewall / SSH Hardening                 │
│ [12] Backup           Backup & Restore                         │
│ [13] Uninstall        Remove Klipper Stack                     │
│ [14] Printer Config   Create printer.cfg                       │
│ [15] Auto-Restart     Service Health Watch                     │
│ [16] OctoPrint        Install OctoPrint                        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Neue Features in v2.1

### ✅ ASCII Boxes komplett überarbeitet
- Einheitliche Breite (70 Zeichen)
- Dynamische Funktionen für Boxen
- Bessere Lesbarkeit

### ✅ KlipperScreen integriert
- Option 4 → Vision Stack → KlipperScreen

### ✅ Moonraker Update Manager
- Automatische Updates für alle Komponenten:
  - Klipper
  - Moonraker
  - Mainsail / Fluidd / HORIZON
  - Crowsnest
  - KlipperScreen
  - Happy Hare
  - OctoPrint
  - KATANA-FLOW

### ✅ Printer Config Wizard (NEU - Option 14)
- Basic printer.cfg
- Ender-3 Template
- Voron 2.4 / Trident Template
- Custom Template

### ✅ Auto-Restart Services (NEU - Option 15)
- Klipper auto-restart bei Absturz
- Moonraker auto-restart
- Crowsnest / KlipperScreen Support
- Health Status Anzeige

### ✅ OctoPrint Support (NEU - Option 16)
- OctoPrint Installation
- OctoPrint + Klipper Plugin
- SystemD Service Integration

### ✅ SSH Hardening erweitert
- UFW Firewall
- SSH Key-basierte Auth
- Root Login deaktivieren
- Port ändern (optional)
- Password Auth deaktivieren

### ✅ Log2Ram Support
- SD-Karten Schutz
- Logs im RAM speichern

---

## Feature Matrix

```
                        KIAUH    KATANAOS v2.1
                        ─────    ──────────────
Klipper                   ✅         ✅
Moonraker                 ✅         ✅
Mainsail                  ✅         ✅
Fluidd                    ✅         ✅
Crowsnest                 ❌         ✅
KlipperScreen             ❌         ✅
Happy Hare                ❌         ✅
Smart Probe               ❌         ✅
OctoPrint                 ❌         ✅ ⚠️ NEW
Backup/Restore            ⚠️         ✅
UFW Firewall              ❌         ✅
SSH Hardening             ❌         ✅ ⚠️ NEW
Log2Ram                  ❌         ✅ ⚠️ NEW
Auto-Restart             ❌         ✅ ⚠️ NEW
Printer Config Wizard     ❌         ✅ ⚠️ NEW
Update Manager           ⚠️         ✅
Engine Switch             ❌         ✅
Diagnostics               ❌         ✅
KATANA FLOW               ❌         ✅
HORIZON UI                ❌         ✅
```

---

## Was noch fehlt

### 🔴 Kritisch
| Feature | Status |
|---------|--------|
| Multi-Machine Support | ❌ |
| Touchscreen Wizard | ❌ |

### 🟡 Wichtig
| Feature | Status |
|---------|--------|
| Theme Builder | ❌ |
| Plugin Manager | ⚠️ Moonraker Only |

---

## Upgrade Anleitung

1. Alte Dateien sichern
2. `scp -r KATANA-Klipper-Installer-main pi@192.168.178.70:~/`
3. Auf Pi: `./katanaos.sh`

---

> **KATANAOS v2.1** - Production-Grade Klipper Installation

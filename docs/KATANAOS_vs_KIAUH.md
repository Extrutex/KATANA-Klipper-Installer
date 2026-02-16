# ⚔️ KATANAOS vs. KIAUH - Umfassender Vergleich

> **KIAUH war der Wegbereiter. Aber 2026 ist KATANAOS der bessere Weg.**

---

## Der Paradigmenwechsel: Werkzeugkasten vs. Autopilot

| Aspekt | KIAUH | KATANAOS |
|--------|-------|----------|
| **Philosophie** | Werkzeugkasten (manuell) | Autopilot (automatisch) |
| **Installation** | 5+ Menüs durchklicken | 1 Befehl: `./katanaos.sh` |
| **Architektur** | Monolithisch (~2000 Zeilen) | Modular (core/ + modules/) |
| **Version** | v3.x (2022) | v2.1 (2026) |
| **Menü** | ASCII Basic | ASCII Professionell |

---

## Was KATANAOS BESSER macht

### 1. ✅ Professionelles Menü-System

**KIAUH:**
- Unübersichtliche Numerierung
- Keine visuelle Gruppierung
- Farblose ASCII-Boxen

**KATANAOS:**
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
└──────────────────────────────────────────────────────────────────┘
```

### 2. ✅ Security ab Werk (Production-Grade)

**KIAUH:** System ist "nackt" - jeder Port offen

**KATANAOS:**
- **UFW Firewall** - Nur SSH(22), HTTP(80), API(7125) offen
- **SSH Hardening** - Key-Auth only, Root-Login aus
- **Log2Ram** - Schont die SD-Karte
- **Nginx Hardening** - Security Headers
- **Auto-Restart** - Services starten bei Absturz automatisch neu

### 3. ✅ The Forge (CAN-Bus Automatisierung)

**KIAUH:** Manuell mit Wiki

**KATANAOS:** Automatische Erkennung & Konfiguration

### 4. ✅ KlipperScreen integriert

**KIAUH:** ❌ Nicht vorhanden

**KATANAOS:** ✅ Option 4 → Vision Stack

### 5. ✅ OctoPrint Support

**KIAUH:** ❌ Nicht vorhanden

**KATANAOS:** ✅ Option 16

### 6. ✅ Printer Config Wizard

**KIAUH:** Manuell

**KATANAOS:** ✅ Option 14 - Templates für:
- Basic
- Ender-3
- Voron 2.4 / Trident
- Custom

### 7. ✅ Multi-Engine Support

- Klipper (Standard)
- Kalico (High-Performance MPC)
- RatOS (RatRig Fork)
- Wechsel per Engine Switch (Option 6)

### 8. ✅ KATANA FLOW

- Smart Purge
- Adaptive Mesh (KAMP integriert)
- ShakeTune (Vibrationsanalyse)

### 9. ✅ Dr. KATANA Diagnostics

- Log-Analyse
- Service-Status Prüfung
- Automatische Repair-Funktionen
- Permission Fixer

### 10. ✅ Backup & Restore

- Vollständige System-Sicherung
- Wiederherstellung mit einem Befehl
- Externe Speicher-Unterstützung

### 11. ✅ Happy Hare & Smart Probe

- Automatische Treiber-Installation
- udev-Regeln werden gemanagt
- Hardware Menu (Option 10)

### 12. ✅ HORIZON UI (Next-Gen)

- Modernes React Dashboard
- In Entwicklung (horizon/ Ordner)
- Via Option 3 → 3 installierbar

---

## Feature Matrix (Stand v2.1)

```
                        KIAUH    KATANAOS
                        ─────    ────────
Klipper                   ✅         ✅
Moonraker                 ✅         ✅
Mainsail                  ✅         ✅
Fluidd                    ✅         ✅
Crowsnest                 ❌         ✅
KlipperScreen             ❌         ✅
Happy Hare                ❌         ✅
Smart Probe               ❌         ✅
OctoPrint                 ❌         ✅
CAN-Bus                   ⚠️         ⚠️
Backup/Restore            ⚠️         ✅
UFW Firewall              ❌         ✅
SSH Hardening            ❌         ✅
Log2Ram                  ❌         ✅
Auto-Restart             ❌         ✅
Printer Config Wizard    ❌         ✅
Update System             ⚠️         ✅
Engine Switch             ❌         ✅
Diagnostics               ❌         ✅
KATANA FLOW               ❌         ✅
HORIZON UI                ❌         ✅
```

---

## Menü-Übersicht KATANAOS v2.1

| Option | Name | Beschreibung |
|--------|------|--------------|
| 1 | Full Install | Komplett-Installation |
| 2 | Core Firmware | Klipper / Kalico / RatOS |
| 3 | Web UI | Mainsail / Fluidd / HORIZON |
| 4 | Vision Stack | Crowsnest / KlipperScreen |
| 5 | The Forge | Flash MCU / CAN-Bus |
| 6 | Engine Switch | Zwischen Firmware wechseln |
| 7 | Update | Klipper & Moonraker |
| 8 | Diagnostics | Log-Analyse & Repair |
| 9 | KATANA FLOW | Smart Purge / Adaptive Mesh |
| 10 | Hardware | Happy Hare / Smart Probe |
| 11 | Security | Firewall / SSH Hardening |
| 12 | Backup | Backup & Restore |
| 13 | Uninstall | Entfernen |
| 14 | Printer Config | printer.cfg erstellen |
| 15 | Auto-Restart | Service Health Watch |
| 16 | OctoPrint | OctoPrint installieren |

---

## Was KIAUH noch voraus hat

### ❌ Stabilität
- KIAUH wird seit Jahren genutzt
- Alle Bugs sind bekannt
- KATANAOS muss sich noch beweisen

### ❌ Community Support
- Große Nutzerbasis
- Viele Tutorials
- Schnelle Hilfe bei Problemen

### ❌ Dokumentation
- Umfangreiche Docs online
- KATANAOS: docs/ Ordner wird erstellt

---

## Was bei KATANAOS noch fehlt

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

## Fazit

**KATANAOS übertrifft KIAUH weil:**

1. **Modern** - Modular, farbig, strukturiert
2. **Sicherer** - Firewall, SSH Hardening, Log2Ram ab Werk
3. **Kompletter** - Alle Features integriert (16 Optionen!)
4. **Zukunftsfähig** - Mit HORIZON WebUI
5. **Aktiver** - Wird 2026 noch entwickelt
6. **Auto-Restart** - Services überleben Neustarts
7. **Printer Config** - Einfache Config-Erstellung

**ABER:** Vor Release 1.0 muss es noch ausführlich getestet werden!

---

> *KIAUH war der Wegbereiter. KATANAOS ist der Nachfolger.*
> *Upgrade to Pro-Grade.*

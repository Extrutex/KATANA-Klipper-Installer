# ⚔️ KATANAOS vs. KIAUH - Ehrlicher Vergleich

> **Stand: v2.2 — Nur tatsächlich funktionale Features werden gezählt.**

---

## Der Unterschied

| Aspekt | KIAUH | KATANAOS |
|--------|-------|----------|
| **Philosophie** | Werkzeugkasten (manuell) | Autopilot (automatisch) |
| **Installation** | Mehrere Menüs durchklicken | 1 Tastendruck: Quick Start |
| **Architektur** | Monolithisch | Modular (core/ + modules/) |
| **Sprache** | Bash | Bash |
| **Menüpunkte** | ~6 | 6 (konsolidiert) |
| **MCU Flash** | Manuell + Wiki | lsusb Auto-Detection + DFU |

---

## Feature-Vergleich

### Kern-Features

| Feature | KIAUH | KATANAOS | Vorteil |
|---------|-------|----------|---------|
| Klipper installieren | ✅ | ✅ | Gleich |
| Moonraker installieren | ✅ | ✅ | Gleich |
| Mainsail installieren | ✅ | ✅ | Gleich |
| Fluidd installieren | ✅ | ✅ | Gleich |
| Firmware bauen | ✅ menuconfig | ✅ menuconfig | Gleich |
| Firmware flashen | ✅ manuell | ✅ **auto-detect USB** | KATANA |
| Updaten | ✅ | ✅ auto-branch | KATANA |
| Uninstall | ✅ | ✅ | Gleich |

### Extras

| Feature | KIAUH | KATANAOS |
|---------|-------|----------|
| Crowsnest | ❌ | ✅ |
| KlipperScreen | ❌ | ✅ |
| Engine Switch (Kalico/RatOS) | ❌ | ✅ |
| Smart Probes (Beacon/Carto/Eddy) | ❌ | ✅ |
| ShakeTune | ❌ | ✅ |
| Multi-Material (Happy Hare) | ❌ | ✅ |
| Backup & Restore | ❌ | ✅ |
| Profile (minimal/standard/power) | ❌ | ✅ |
| System Status Dashboard | ❌ | ✅ |
| Diagnose (Logs/Repair) | ❌ | ✅ |
| PolicyKit Auto-Setup | ❌ | ✅ |
| USB Device Scan (lsusb) | ❌ | ✅ |
| DFU Auto-Flash | ❌ | ✅ |
| Linux Host MCU (automatisch) | ❌ | ✅ |
| Post-Install Summary | ❌ | ✅ |

### Was KIAUH noch voraus hat

| Aspekt | Details |
|--------|---------|
| **Stabilität** | Seit Jahren im Einsatz, alle Bugs bekannt |
| **Community** | Große Nutzerbasis, viele Tutorials |
| **Dokumentation** | Umfangreiche Docs + Wiki |
| **Testing** | Durch tausende User getestet |

---

## Menü-Vergleich

**KIAUH:**
```
 1) [Install]
 2) [Remove]
 3) [Update]
 4) [Advanced]
 Q) Exit
```

**KATANAOS v2.2:**
```
 [1] QUICK START      Auto-Pilot Installation
 [2] FORGE            Build & Flash MCU Firmware
 [3] EXTRAS           Vision / Probes / System / Tools
 [4] UPDATE           Klipper & Moonraker
 [5] DIAGNOSE         Service Status / Logs / Repair
 [6] SETTINGS         Profile / Engine / CAN / Uninstall
```

---

## Fazit

**KATANAOS überholt KIAUH bei:**
1. **Forge** — USB-Erkennung und Auto-Flash statt manueller Wiki-Anleitung
2. **Extras** — Crowsnest, KlipperScreen, Smart Probes integriert
3. **Engine Switch** — Klipper ↔ Kalico ↔ RatOS mit einem Klick
4. **Diagnose** — Eingebaute Service-Checks und Log-Viewer
5. **Profiles** — Vorkonfigurierte Installation statt Einzelauswahl

**KIAUH bleibt besser bei:**
1. **Stabilität** — Jahrelang getestet
2. **Community** — Mehr Tutorials und Support

> **KATANAOS ist der modernere Ansatz. Aber KIAUH hat die Battle-Tested Reality.**
> Sobald KATANAOS v1.0-stable erreicht, gibt es keinen Grund mehr für KIAUH.

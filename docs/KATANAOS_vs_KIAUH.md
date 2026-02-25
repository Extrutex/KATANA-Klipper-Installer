# KATANAOS vs. KIAUH

## Was KIAUH kann

Install, Update, Remove von:
Klipper, Moonraker, Mainsail, Fluidd, KlipperScreen, OctoPrint, Telegram Bot, Obico, Mobileraker, PrettyGCode, OctoEverywhere, OctoApp, Klipper-Backup, SimplyPrint.

Das war's. Kein Firmware-Flash. Kein MCU-Handling. Keine Diagnose.

## Was KIAUH NICHT kann

| Feature | KIAUH | KATANAOS |
|---------|:-----:|:--------:|
| MCU Firmware bauen + flashen | ❌ | ✅ `menuconfig` + auto-flash |
| USB Device Scan (`lsusb`) | ❌ | ✅ STM32 DFU, Katapult, Klipper USB |
| DFU Auto-Flash | ❌ | ✅ erkennt `0483:df11` → flasht automatisch |
| Linux Host MCU | ❌ | ✅ auto-configure + service |
| CAN-Bus Setup | ❌ | ✅ Wizard mit Firmware-Build |
| Katapult Bootloader | ❌ | ✅ Build + Flash |
| Engine Switch | ❌ | ✅ Klipper ↔ Kalico ↔ RatOS |
| Smart Probes | ❌ | ✅ Beacon, Cartographer, BTT Eddy |
| Backup & Restore | ❌ | ✅ ZIP + Git Push + Rotation |
| Diagnose & Logs | ❌ | ✅ Service Status, dmesg, Repair |
| PolicyKit Setup | ❌ | ✅ Automatisch für Moonraker |
| Post-Install Summary | ❌ | ✅ Checkmarks nach Installation |
| Install-Profile | ❌ | ✅ minimal / standard / power |
| 1-Click Full Install | ❌ | ✅ Quick Start Auto-Pilot |

## Was KIAUH hat, das KATANA (noch) nicht hat

| Feature | Status |
|---------|--------|
| Telegram Bot | nicht geplant |
| Obico / OctoEverywhere | nicht geplant |
| Mobileraker Companion | nicht geplant |
| PrettyGCode | nicht geplant |
| SimplyPrint | nicht geplant |
| OctoApp | nicht geplant |

> Cloud-Services und Bot-Integrationen sind kein Kern-Feature eines Installers.
> KATANA fokussiert auf das, was auf der Maschine läuft.

## Technischer Unterschied

| Aspekt | KIAUH | KATANAOS |
|--------|-------|----------|
| Sprache | Python (seit v5) | Bash |
| Abhängigkeit | Python 3.8+ | keine |
| Root-Check | ✅ | ✅ |
| Modular | teilweise | ja (core/ + modules/) |
| RatOS Support | ❌ explizit blockiert | ✅ Engine Switch |

KIAUH blockiert RatOS aktiv (`check_if_ratos` → exit 1). KATANA unterstützt es.

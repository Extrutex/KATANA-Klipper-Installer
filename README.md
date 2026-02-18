<div align="center">
<img width="904" height="1878" alt="KATANAOS (2)" src="https://github.com/user-attachments/assets/a6eaadc8-6642-4374-935b-57186cad3d5a" />


  <h1>⚔️ KATANAOS - Pro-Grade Klipper Suite</h1>


  <a href="https://www.gnu.org/licenses/gpl-3.0">
    <img src="https://img.shields.io/badge/License-GPLv3-blueviolet.svg" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Platform-Debian%20%7C%20Raspbian%20%7C%20Armbian-ff00bf.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Bash%20Script-00ffff.svg" alt="Language">


  <br/><br/>


  <p>
    <b>Opinionated automation for the modern 3D printing stack.</b><br>
    Deploys a hardened, fully configured Klipper environment in minutes.
  </p>
</div>


<hr/>


## ⚡ Overview

**KATANAOS** is a CLI management suite engineered to streamline the deployment and maintenance of the Klipper ecosystem. Unlike modular toolboxes that require extensive manual menu navigation, KATANAOS utilizes an **"Auto-Pilot" workflow** to provision the entire stack (Firmware, API, Reverse Proxy, HMI) in a single execution pass.

It is designed for users who treat their 3D printer as a production appliance, prioritizing **speed, stability, and reproducible configuration** over manual tinkering.


## 📦 Features


### ⚡ Quick Start (Auto-Pilot)
One-click installation of the full Klipper stack with profile support.
- **Profiles:** `minimal` (Klipper + Moonraker), `standard` (+ Mainsail), `power` (everything)
- **Includes:** Klipper, Moonraker, Mainsail/Fluidd, Nginx, PolicyKit, systemd services
- **Post-Install:** Visual summary with checkmarks showing what was installed


### 🔥 THE FORGE - MCU Firmware Manager
Build and flash firmware for any Klipper-supported board.
- **Universal:** Uses Klipper's `menuconfig` — supports every board Klipper supports
- **Auto-Detection:** Scans USB devices via `lsusb` to find boards in DFU/bootloader mode
- **Smart Flash:** Auto-detects `0483:df11` (STM32 DFU), `1d50:614e` (Klipper USB), `/dev/serial/by-id/`
- **Flash Methods:** DFU (auto), USB Serial (auto), SD Card (manual), CAN Bus (Katapult)
- **Linux Host MCU:** Fully automatic build & install for Raspberry Pi host MCU
- **Handles known quirks:** Recognizes successful DFU flash despite `dfu-util` detach errors


### 🔄 Engine Switch
Switch between Klipper firmware variants without reinstalling.
- **Klipper** (upstream) ↔ **Kalico** (fork) ↔ **RatOS** (fork)
- Automatic detection of current engine via symlink/directory analysis


### 👁️ Vision Stack
Camera and touch display support.
- **Crowsnest** - Webcam Streaming Daemon
- **KlipperScreen** - Touch UI for direct printer control


### 🔌 Smart Probes
One-click installation for modern Z-probes.
- **Beacon** - Eddy Current Probe
- **Cartographer** - High-speed inductive probe
- **BTT Eddy** - BigTreeTech Eddy Current Probe


### 🧩 Extras
Additional printing tools and macros.
- **ShakeTune** - Input Shaper analysis
- **KATANA-FLOW** - Smart Purge & Park (KAMP replacement)
- **Multi-Material** - Happy Hare / Monolith support


### 💾 Backup & Restore
Automated backup system for Klipper configs.
- **ZIP Backups** with automatic rotation (keeps last 5)
- **Git Push** for version-controlled config backups
- **Restore** from any backup with service stop/start handling


### � Update Manager
Keep your stack current.
- **Auto-detects** git branch (`master` vs `main`) per repository
- Updates Klipper, Moonraker, or both with rebuild and service restart


### 🩺 Diagnostics
System health monitoring and repair.
- **Service Status** - Check all running services
- **Log Viewer** - Klipper, Moonraker, dmesg logs
- **Repair** - Restart services, validate config
- **Emergency** - Full reinstall or complete uninstall


### � System Status Dashboard
Real-time status display in the main menu.
- Shows Engine status (Klipper/Kalico/RatOS) with online/offline indicator
- Shows Moonraker status with online/offline indicator
- Updates every time the main menu is rendered


## 🛠️ Usage

**Requirements:**
- Hardware: Raspberry Pi (3/4/5/Zero2), Orange Pi, or generic Linux host
- OS: Raspberry Pi OS Lite (Bookworm/Bullseye) or Debian-based
- User: Standard user with `sudo` privileges


### Installation

**Step 1: Update system & install Git**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git
```

**Step 2: Clone & run KATANA**
```bash
cd ~
git clone https://github.com/Extrutex/KATANA-Klipper-Installer.git
cd KATANA-Klipper-Installer
chmod +x katanaos.sh
./katanaos.sh
```

**Optional: Remove legacy KIAUH**
```bash
rm -rf ~/kiauh
```


### 🚀 First Time Setup

If this is a **fresh installation**, follow this order:

```
Step 1:  [1] QUICK START → Full Install     (installs Klipper + Moonraker + Web UI)
Step 2:  [2] FORGE → Build & Flash MCU      (compiles firmware for your board)
Step 3:  [3] EXTRAS → Install extensions     (optional: Crowsnest, probes, etc.)
```

> ⚠️ **The FORGE requires Klipper to be installed first!**
> It compiles firmware from the Klipper source code (`~/klipper`).
> Always run **Quick Start** first on a fresh system.


### � Menu Structure

```
╔══════════════════════════════════════════════════════════════════════╗
║                    KATANAOS v2.2 - MAIN MENU                       ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  [1]  QUICK START         Auto-Pilot Installation                  ║
║  [2]  FORGE               Build & Flash MCU Firmware               ║
║  [3]  EXTRAS              Vision / Probes / System / Tools         ║
║  [4]  UPDATE              Klipper & Moonraker                      ║
║  [5]  DIAGNOSE            Service Status / Logs / Repair           ║
║  [6]  SETTINGS            Profile / Engine / CAN / Uninstall       ║
║                                                                    ║
║  [X]  EXIT                                                         ║
╚══════════════════════════════════════════════════════════════════════╝
```

#### [1] Quick Start
Installs the full Klipper stack based on your selected profile (minimal/standard/power).

#### [2] Forge
Opens Klipper's `menuconfig`, compiles firmware, scans USB for connected boards, and flashes automatically.

#### [3] Extras
| Submenu | Contents |
|---|---|
| Web UI | Install/switch Mainsail or Fluidd |
| Vision | Crowsnest, KlipperScreen |
| Smart Probes | Beacon, Cartographer, BTT Eddy |
| Printing | ShakeTune, KATANA-FLOW, Multi-Material |
| System | Backup, Restore, Log2Ram |

#### [4] Update
Updates Klipper and/or Moonraker to latest version from GitHub.

#### [5] Diagnose
Check service status, view logs, restart services, emergency reinstall.

#### [6] Settings
Change profile, switch engine (Klipper/Kalico/RatOS), manage instances, CAN-Bus setup, uninstall.


## License

KATANAOS is free software distributed under the terms of the GNU GPLv3 license.


## Author

**KATANAOS** created by **Extrutex**.

If this script saved you time, consider supporting the project:
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://Ko-fi.com/3dw_sebastianwindt)

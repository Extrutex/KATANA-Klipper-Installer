<div align="center">
<img width="1065" height="967" alt="KATANAOS (3)" src="https://github.com/user-attachments/assets/b0349cc9-87d3-4dc7-b240-b1a6e9dfb27d" />


  <h1>⚔️ KATANAOS - Pro-Grade Klipper Suite</h1>


  <a href="https://www.gnu.org/licenses/gpl-3.0">
    <img src="https://img.shields.io/badge/License-GPLv3-blueviolet.svg" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Platform-Debian%20%7C%20Raspbian%20%7C%20Armbian-ff00bf.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Bash%20Script-00ffff.svg" alt="Language">
  <img src="https://img.shields.io/badge/Security-Hardened%20(Audit%20Phase%204)-success.svg" alt="Security">


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
- **KATANA-FLOW** - Smart Park (No-Retract) & X-Blade Purge (Cross-Pattern)
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

### 🚀 Installation (Recommended)

The fastest way to install or update KATANA. Just copy and paste this command into your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/Extrutex/KATANA-Klipper-Installer/main/install.sh | bash
```
(This script will automatically install git, clone the repository, and start the installer.)

⚙️ Manual Installation (Alternative)
If you prefer to install manually without the automated script:

Step 1: Update system & install prerequisites

````bash
sudo apt-get update && sudo apt-get full-upgrade -y
sudo apt-get install -y git
````

Step 2: Clone & run KATANA

```bash
cd ~
git clone https://github.com/Extrutex/KATANA-Klipper-Installer.git 
cd KATANA-Klipper-Installer
chmod +x katanaos.sh
./katanaos.sh
```

Optional: Remove legacy KIAUH

```bash
rm -rf ~/kiauh
````

### 🚀 First Time Setup

If this is a **fresh installation**, follow this order:

```
Step 1:  [1] QUICK START → Full Install          (MANDATORY: Installs Klipper, Moonraker, UI)
Step 2:  [2] FORGE       → Build "Linux Process" (MANDATORY: Flashes RPi as Host MCU)
Step 3:  [2] FORGE       → Build Printer MCUs    (Flashes your Octopus, Toolhead, etc.)
```

> ⚠️ **CRITICAL ORDER OF OPERATIONS:**
> 1. You **MUST** run **Quick Start** first to get the Klipper source code.
> 2. You **MUST** build the **Linux Host MCU** before adding other printers (services depend on it).
> 3. Only **THEN** flash your printer mainboards and toolboards.


### 📖 How-To: Add a Toolhead (CAN or USB) - The One-Click Way

To use **"One-Click Updates"** (no jumpers, no buttons), follow this workflow for **ANY** board (CAN or USB):

#### A) The Bootloader (Katapult) - *The Foundation*
_(Skip if your board already has CanBoot/Katapult pre-installed)_
1.  Connect board via **USB** (hold Boot button).
2.  Go to `[2] Forge -> [3] Katapult Manager -> [2] Install Katapult`.
3.  Select your board (e.g., SB2209, EBB36, Nitehawk).
    - **For CAN:** Katapult installs in CAN mode.
    - **For USB:** Katapult installs in USB mode.

#### B) The Firmware (Klipper) - *The Brain*
1.  Go to `[2] Forge -> [1] Build & Flash`.
2.  Configure `menuconfig`:
    - **CAN Board:** `Communication interface: CAN bus (PB0/PB1)`.
    - **USB Board:** `Communication interface: USB`.
    - **Bootloader Offset:** `8KiB` (Required!).
3.  **Build**.
4.  **SAVE CONFIG:** When asked, say **YES**. Name it (e.g., `Nitehawk_USB` or `SB2240_CAN`).
    - **Connection Method:**
        - Select `[2] CAN Bus` (if you will use it via CAN).
        - Select `[1] USB` (if you will use it via USB).
5.  **FLASH:**
    - If connecting via USB for the first time: Choose `[1] Flash via DFU` (or Katapult).

#### C) Future Updates ( The Magic ✨ )
Connect the board normally (CAN or USB).
Run `[2] Forge -> [4] Update All Saved MCUs`.
KATANA will rebuild and flash it automatically. **No boot buttons. No jumpers.**


### � Menu Structure

```

╔════════════════════════════════════════════════════════════════════╗
║                    KATANAOS v2.6 - MAIN MENU                       ║
╠════════════════════════════════════════════════════════════════════╣
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  [1]  QUICK START         Auto-Pilot Installation                  ║
║  [2]  FORGE               Build & Flash MCU Firmware               ║
║  [3]  EXTRAS              Vision / Probes / System / Tools         ║
║  [4]  UPDATE              Klipper & Moonraker                      ║
║  [5]  DIAGNOSE            Service Status / Logs / Repair           ║
║  [6]  SETTINGS            Profile / Engine / CAN / Uninstall       ║
║                                                                    ║
║  [X]  EXIT                                                         ║
╚════════════════════════════════════════════════════════════════════╝
```

#### [1] Quick Start
Installs the full Klipper stack based on your selected profile (minimal/standard/power).

#### [2] Forge
Opens Klipper's `menuconfig`, compiles firmware, scans USB for connected boards, and flashes automatically. Includes **RP2040 Safety Lock** and **Smart Artifact Detection**.

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

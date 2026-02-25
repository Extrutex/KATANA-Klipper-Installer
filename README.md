<div align="center">
<img width="1065" height="967" alt="KATANAOS (3)" src="https://github.com/user-attachments/assets/b0349cc9-87d3-4dc7-b240-b1a6e9dfb27d" />


  <h1>⚔️ KATANAOS v2.6 — Pro-Grade Klipper Suite</h1>


  <a href="https://www.gnu.org/licenses/gpl-3.0">
    <img src="https://img.shields.io/badge/License-GPLv3-blueviolet.svg" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Platform-Debian%20%7C%20Raspbian%20%7C%20Armbian-ff00bf.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Bash%20Script-00ffff.svg" alt="Language">
  <img src="https://img.shields.io/badge/Workflow-3%20Phase%20Flash-success.svg" alt="Workflow">


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


## 🛠️ Installation

```bash
sudo apt-get update && sudo apt-get full-upgrade -y
sudo apt-get install -y git

cd ~
git clone https://github.com/Extrutex/KATANA-Klipper-Installer.git katana-os
cd katana-os
chmod +x katanaos.sh
./katanaos.sh
```


## 📊 Main Menu

```
╔══════════════════════════════════════════════════════════════╗
║                  KATANAOS v2.6 — MAIN MENU                   ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  [1]  QUICK START         Auto-Pilot Installation            ║
║  [2]  FORGE               Build & Flash MCU Firmware         ║
║  [3]  EXTRAS              Vision / Probes / Tuning / Tools   ║
║  [4]  UPDATE              Klipper & Moonraker                ║
║  [5]  DIAGNOSE            Service Status / Logs / Repair     ║
║  [6]  SETTINGS            Profile / Engine / CAN / Uninstall ║
║                                                              ║
║  [X]  EXIT                                                   ║
╚══════════════════════════════════════════════════════════════╝
```


## 📦 Features


### ⚡ [1] Quick Start (Auto-Pilot)
One-click installation of the full Klipper stack.
- **Profiles:** `minimal` (Klipper + Moonraker), `standard` (+ Mainsail), `power` (everything)
- **Includes:** Klipper, Moonraker, Mainsail/Fluidd, Nginx, PolicyKit, systemd services


### 🔥 [2] THE FORGE — MCU Firmware Manager

```
  [1]  Katapult (Bootloader)      (Step 1: Flash Bootloader)
  [2]  Build Klipper Firmware     (Step 2: Build & Flash Klipper)
  [3]  Saved Boards Manager       (Manage saved configs)
  [4]  Linux Host MCU             (Raspberry Pi as MCU)
  [5]  CAN-Bus Setup              (Network & Interface)
  [6]  MCU Scanner                (Show all CAN/USB devices)

  [C]  Clear Workflow State       (Reset)
```

**Key Features:**
- **3-Phase Build & Flash Workflow** — Phase 1: Pre-Flight, Phase 2: Configure & Build, Phase 3: Flash & Verify
- **Workflow State Persistence** — Remembers what you did last. After flashing Katapult, it suggests continuing with Klipper
- **MCU Scanner** — Shows all CAN UUIDs and USB serial paths, ready to copy-paste into `printer.cfg`
- **Post-Flash Verification** — After flashing, automatically scans for the MCU to prove it's online
- **CAN-Bus Setup** — Configure `can0` interface directly from FORGE (no longer hidden in Settings)


### 🧩 [3] Extras

All extras support both **Install and Remove**:

| Category | Tools |
|---|---|
| **Smart Probes** | Beacon, Cartographer, BTT Eddy |
| **Tuning** | ShakeTune (Input Shaper), Log2Ram |
| **Print Macros** | KATANA-FLOW (START → PARK → PURGE → END) |
| **Multi-Material** | Happy Hare (ERCF), StealthChanger, MADMAX |
| **Toolchanger** | Quick Setup (2/4/6 tools), Custom |
| **Vision** | Crowsnest, KlipperScreen |


### ♻️ [4] Update Manager
- Updates Klipper, Moonraker, UI, or all at once
- Auto-detects git branch (`master` vs `main`)


### 🩺 [5] Diagnostics
- **Service Status** — Check all running services
- **Log Viewer** — Klipper, Moonraker, dmesg logs
- **Repair** — Restart services, validate config
- **Emergency** — Full reinstall or complete uninstall


### ⚙️ [6] Settings
- Profile management (minimal / standard / power)
- Engine Switch (Klipper ↔ Kalico ↔ RatOS)
- Instance Manager
- Uninstall


## 🚀 First Time Setup

Follow this order for a clean installation:

```
Step 1:  [1] QUICK START              → Install Klipper, Moonraker, UI
Step 2:  [2] FORGE → [4] Linux MCU    → Flash Raspberry Pi as Host MCU
Step 3:  [2] FORGE → [1] Katapult     → Flash Bootloader on your board
Step 4:  [2] FORGE → [2] Build Klipper → Build & Flash Klipper firmware
```

> ⚠️ **CRITICAL ORDER:**
> 1. **Quick Start** first — installs Klipper source code
> 2. **Linux Host MCU** before anything else
> 3. **Katapult** (Bootloader) before Klipper firmware
> 4. KATANAOS remembers your progress — stop after any step and resume later


### 📖 Adding a Board (CAN or USB)

**Step 1 — Bootloader (Katapult):**
1. Connect board via USB (hold Boot button)
2. `[2] FORGE → [1] Katapult → Build → Flash`

**Step 2 — Firmware (Klipper):**
1. `[2] FORGE → [2] Build Klipper Firmware`
2. Configure in menuconfig → Build → Flash
3. MCU Scanner shows UUID/Serial → copy into `printer.cfg`

**Future Updates:**
1. `[2] FORGE → [3] Saved Boards → Update`
2. No boot buttons. No jumpers.


## Requirements

- **Hardware:** Raspberry Pi (3/4/5/Zero2), Orange Pi, or generic Linux host
- **OS:** Raspberry Pi OS Lite (Bookworm/Bullseye) or Debian-based
- **User:** Standard user with `sudo` privileges


## License

KATANAOS is free software distributed under the terms of the GNU GPLv3 license.


## Author

**KATANAOS** created by **Extrutex**.

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://Ko-fi.com/3dw_sebastianwindt)

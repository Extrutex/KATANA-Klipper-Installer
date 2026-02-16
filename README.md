<div align="center">
  <img width="521" height="555" alt="KATANAOS" src="https://github.com/user-attachments/assets/29bea3fd-2b84-47d7-a067-60f1c0dd0ba6" />


  <h1>⚔️ KATANAOS - Pro-Grade Klipper Suite</h1>


  <a href="https://www.gnu.org/licenses/gpl-3.0">
    <img src="https://img.shields.io/badge/License-GPLv3-blueviolet.svg" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Platform-Debian%20%7C%20Raspbian%20%7C%20Armbian-ff00bf.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Bash%20Script-00ffff.svg" alt="Language">


  <br/><br/>


  <p>
    <b>Opinionated automation for the modern 3D printing stack.</b><br>
    Deploys a hardened, fully configured Klipper environment (including essential macros) in minutes.
  </p>
</div>


<hr/>


## ⚡ Overview


**KATANAOS** is a CLI management suite engineered to streamline the deployment and maintenance of the Klipper ecosystem. Unlike modular toolboxes that require extensive manual menu navigation, KATANAOS utilizes an **"Auto-Pilot" workflow** to provision the entire stack (Firmware, API, Reverse Proxy, HMI) in a single execution pass.


It is designed for users who treat their 3D printer as a production appliance, prioritizing **security, stability, and reproducible configuration** over manual tinkering.


## 📦 Features


### 🟣 Deployment Matrix
A real-time dashboard that verifies the installation state of all stack components.
- **Function:** Checks for Klipper, Moonraker, UI frontends, and system services.
- **Purpose:** Provides immediate visual feedback on which parts of the ecosystem are deployed.


### ⚡ Dynamic Nginx Management
KATANAOS handles the reverse proxy configuration automatically.
- **Feature:** Switch between **Mainsail** and **Fluidd** instantly via the menu.
- **Mechanism:** The script rewrites the Nginx site configuration and restarts the service seamlessly.


### 🔥 THE FORGE - MCU Manager
A dedicated engine for MCU management and communication.
- **Quick Build:** Preconfigured builds for 9 popular boards:
  - BTT Octopus F446 v1.1, F429, H723
  - Raspberry Pi RP2040 (Generic)
  - BTT SKR E3 Turbo, SKR 3
  - Fysetc Cheetah v2.0
  - Fly Gemini S, BTT GTR, BTT E3 RRF
- **Katapult Bootloader:** Install and flash via CAN-Bus
- **CAN-Bus Network:** Auto-setup with 1M bitrate
- **Flash Methods:** USB, SD Card, Katapult (CAN-Bus)


### 🛠️ Hardware Extensions
Intelligent installation for modern Klipper hardware.
- **StealthChanger** - Toolchanging system for Voron printers
- **MADMAX** - Mechanical tool lock system
- **Cartographer** - High-speed inductive Z-probe
- **Beacon** - Eddy Current Probe for precision Z-mapping
- **BTT Eddy** - BigTreeTech Eddy Current Probe
- **Bed Distance Sensor** - Accelerometer-based Z calibration
- **Happy Hare** - MMU V1/V2/ERCF support


### 👁️ Vision Stack
Full support for local machine interfaces.
- **Crowsnest** - Webcam Streaming Daemon
- **KlipperScreen** - Touch UI for direct printer control


### 🧩 EXTRAS
Advanced printing features.
- **KATANA-FLOW** - Smart Purge & Park (KAMP replacement)
  - Smart Park: Proximity parking to prevent oozing
  - Blade Purge: Pattern purge line following the toolhead
  - Two install variants: Simple Include or Section Header
- **ShakeTune** - Input Shaper analysis and tuning
- **OctoPrint** - Optional remote monitoring support


### 💾 Backup System
Multiple backup strategies for data safety.
- **tar.gz Backups** - Classic directory snapshots
- **Restic** - Encrypted, deduplicated snapshots with verification


### 🛡️ System Hardening
Security is not an option; it is a default.
- **UFW Firewall:** Automated rule generation
- **Log2Ram:** RAM-based logging to protect SD cards


### 🚑 Dr. Katana
Safety net for your printer.
- **Log Analyzer:** Scans logs for common errors
- **Permission Fixer:** Auto-corrects ownership issues
- **Dependency Repair:** Re-installs missing packages


## 🛠️ Usage

**Requirements:**
- Hardware: Raspberry Pi (3/4/5/Zero2), Orange Pi, or generic Linux host
- OS: Debian Bookworm / Bullseye (Lite recommended)
- User: Standard user with `sudo` privileges
- **Git** (if not installed, see below)


### Installation

**Important: Install Git first**
```bash
sudo apt update
sudo apt install git -y
```

**Optional: Remove legacy KIAUH**
```bash
cd ~
rm -rf ~/kiauh
```

**Install KATANAOS**
```bash
cd ~
git clone https://github.com/Extrutex/KATANA-Klipper-Installer.git
cd KATANA-Klipper-Installer
chmod +x katanaos.sh
./katanaos.sh
```


## License

KATANAOS is free software distributed under the terms of the GNU GPLv3 license.


## Author

**KATANAOS** created by **Extrutex**.

If this script saved you time, consider supporting the project:
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://Ko-fi.com/3dw_sebastianwindt)

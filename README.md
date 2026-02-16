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
sudo apt install git
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


### 📋 Menu Reference

After launching `./katanaos.sh`, the main menu appears with a structured interface. Use the number keys (1-15) to navigate and press Enter to execute. Press X to exit.

```
╔══════════════════════════════════════════════════════════════════════╗
║ ⚡ INSTALLER                                                         ║
╠══════════════════════════════════════════════════════════════════════╣
║ [1]  Full Install       Klipper + Moonraker + UI                    ║
║ [2]  Core Firmware      Klipper / Kalico / RatOS                    ║
║ [3]  Web UI             Mainsail / Fluidd                            ║
║ [4]  Vision Stack      Crowsnest / KlipperScreen                    ║
║ [5]  The Forge         MCU Flash / CAN-Bus / Katapult                ║
╠══════════════════════════════════════════════════════════════════════╣
║ 🔧 SYSTEM                                                            ║
╠══════════════════════════════════════════════════════════════════════╣
║ [6]  Engine Switch     Installed: KLIPPER                           ║
║ [7]  Update            Klipper & Moonraker                           ║
║ [8]  Diagnostics       Log Analysis & Repair                        ║
╠══════════════════════════════════════════════════════════════════════╣
║ 🧩 EXTRAS                                                            ║
╠══════════════════════════════════════════════════════════════════════╣
║ [9]  KATANA-FLOW      Smart Purge & ShakeTune                       ║
║ [10] Hardware          Toolchanger / Probes                          ║
╠══════════════════════════════════════════════════════════════════════╣
║ 🔒 MANAGEMENT                                                        ║
╠══════════════════════════════════════════════════════════════════════╣
║ [11] Security          Firewall / SSH Hardening                     ║
║ [12] Backup            Backup & Restore                             ║
║ [13] Uninstall         Remove Klipper Stack                          ║
║ [14] Printer Config    Create printer.cfg                           ║
║ [15] Auto-Restart      Service Health Watch                         ║
╠══════════════════════════════════════════════════════════════════════╣
║ [X]  Exit              Close KATANAOS                               ║
╚══════════════════════════════════════════════════════════════════════╝
```

#### ⚡ INSTALLER
- **[1] Full Install** - Deploys the complete Klipper stack (Klipper, Moonraker, and a web UI) in one go
- **[2] Core Firmware** - Install Klipper, Kalico, or RatOS firmware only
- **[3] Web UI** - Choose and install Mainsail or Fluidd web interface
- **[4] Vision Stack** - Install Crowsnest (webcam streaming) and/or KlipperScreen (touch UI)
- **[5] The Forge** - MCU firmware compilation, flashing, CAN-Bus setup, and Katapult bootloader management

#### 🔧 SYSTEM
- **[6] Engine Switch** - Switch between installed Klipper engines (Klipper, Kalico, RatOS)
- **[7] Update** - Update Klipper and Moonraker to the latest versions
- **[8] Diagnostics** - Run log analysis, fix permissions, and repair dependencies (Dr. Katana)

#### 🧩 EXTRAS
- **[9] KATANA-FLOW** - Install Smart Purge & Park macros and ShakeTune for input shaper analysis
- **[10] Hardware** - Configure tool changers, probes (Cartographer, Beacon, BTT Eddy), and sensors

#### 🔒 MANAGEMENT
- **[11] Security** - Configure UFW firewall and SSH hardening
- **[12] Backup** - Create and restore backups (tar.gz or Restic encrypted backups)
- **[13] Uninstall** - Remove the entire Klipper stack from the system
- **[14] Printer Config** - Generate a basic printer.cfg template
- **[15] Auto-Restart** - Enable service health monitoring with automatic restart on failure

#### Exit
- **[X]** - Exit KATANAOS and return to the terminal


## License

KATANAOS is free software distributed under the terms of the GNU GPLv3 license.


## Author

**KATANAOS** created by **Extrutex**.

If this script saved you time, consider supporting the project:
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://Ko-fi.com/3dw_sebastianwindt)

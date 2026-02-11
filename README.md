<img width="610" height="688" alt="KATANAOS" src="https://github.com/user-attachments/assets/47f710ef-05d4-4dcc-9973-207e3da95182" />

  # ⚔️ KATANAOS - Pro-Grade Klipper Suite

  [![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
  [![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20Raspbian%20%7C%20Armbian-blue.svg)]()
  [![Bash](https://img.shields.io/badge/Language-Bash%20Script-green.svg)]()

  > **Opinionated automation for the modern 3D printing stack.** <br>
  > Deploys a hardened, fully configured Klipper environment in minutes.
</div>

---

## ⚡ Overview

**KATANAOS** is a CLI management suite engineered to streamline the deployment and maintenance of the Klipper ecosystem. Unlike modular toolboxes that require extensive manual menu navigation, KATANAOS utilizes an **"Auto-Pilot" workflow** to provision the entire stack (Firmware, API, Reverse Proxy, HMI) in a single execution pass.

It is designed for users who treat their 3D printer as a production appliance, prioritizing **security, stability, and reproducible configuration** over manual tinkering.

## 📦 Core Architecture

### 1. 🟣 Deployment Matrix
A real-time, pixel-perfect dashboard that verifies the installation state of the stack components.
* **Function:** Checks for Klipper, Kalico, Moonraker, UI frontends, and system services.
* **Purpose:** Provides immediate visual feedback on which parts of the ecosystem are deployed on the host.

### 2. ⚡ Dynamic Nginx Management
KATANAOS handles the reverse proxy configuration automatically.
* **Feature:** Switch between **Mainsail** and **Fluidd** instantly via the menu.
* **Mechanism:** The script rewrites the Nginx site configuration to point to the selected frontend and restarts the service seamlessly.

### 3. 🔥 The Forge (Hardware Automator)
A dedicated engine for MCU management and communication.
* **Smart Flash:** Scans `/dev/serial/by-id/` to detect connected MCUs. Allows direct flashing via a selection menu without manual path copying.
* **Auto CAN-Bus:** Automatically creates the `/etc/network/interfaces.d/can0` interface with **1M bitrate** and optimized `txqueuelen`, eliminating manual Linux network configuration.

### 4. ⚙️ Engine Manager (Dual-Core)
Runtime flexibility for power users.
* **Feature:** Switch between **Klipper** (Standard) and **Kalico** (High-Performance) firmware engines instantly.
* **Mechanism:** Dynamically rewrites systemd service paths to swap the active execution environment without reinstalling or reflashing the SD card.

### 5. 👁️ HMI & Vision Stack
Full support for local machine interfaces.
* **Full Media Stack:** One-click deployment of **Crowsnest** (Webcam Streaming Daemon) and **KlipperScreen** (Touch UI) in a single pass.

### 6. 🧩 Smart Extension Support
Intelligent installation logic for modern Klipper extensions.
* **Smart Probe Selector:** Enforces exclusive installation logic for **Beacon3D** or **Cartographer** to prevent udev conflicts.
* **KAMP:** Clones the repo and injects the update manager entry into `moonraker.conf`.
* **ShakeTune:** Automated installation of the Klippain ShakeTune module.

### 7. 🛡️ System Hardening (Standardized)
Security is not an option; it is a default.
* **UFW Firewall:** Automated rule generation denying all incoming traffic except essential ports (SSH:22, HTTP:80, API:7125).
* **Log2Ram:** Integrates the Log2Ram daemon to redirect system logging to RAM, significantly reducing write cycles on SD cards.

## 🛠️ Usage

**Requirements:**
* Hardware: Raspberry Pi (3/4/5/Zero2), Orange Pi, or generic Linux host.
* OS: Debian Bookworm / Bullseye (Lite recommended).
* User: Standard user with `sudo` privileges.

**Installation:**

```bash
cd ~
git clone [https://github.com/Extrutex/KATANA-Klipper-Installer.git](https://github.com/Extrutex/KATANA-Klipper-Installer.git)
mv KATANA-Klipper-Installer/katanaos.sh .
chmod +x katanaos.sh
./katanaos.sh

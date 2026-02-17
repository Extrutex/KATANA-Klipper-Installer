# Changelog

All notable changes to this project will be documented in this file.

## [v2.2] - 2026-02-17

### Breaking Changes & Community Feedback
- **Menu alignment completely rewritten** - Fixed right-side display issues
- **ANSI color codes fixed** - No more visible escape sequences
- **Service status check improved** - Proper .service suffix handling

### Added
- **Quick CAN Setup Wizard** - One-click CAN-Bus setup in ~2 minutes
  - Auto-configures can0 (1M bitrate)
  - Builds & flashes Katapult bootloader
  - Builds & flashes Klipper via CAN
  - Generates config snippet for printer.cfg
- **Engine Display in System Status** - Shows current firmware (Klipper/Kalico/RatOS) + online/offline
- **Moonraker Update Manager Integration** - Auto-registers:
  - ShakeTune
  - KATANA-FLOW
  - StealthChanger, MADMAX
  - Cartographer, Beacon, BTT Eddy, Bed Distance Sensor
- **Profile Support** - `--profile minimal|standard|power`
- **Safety Rails** - Backup before config writes

### Changed
- Professional boxed menu design with ╔═╗╚═╝ characters
- Dynamic engine switching with atomic swap
- Improved error handling with colored [OK]/[!!] feedback

### Features (KATANAOS vs KIAUH)
| Feature | Status |
|---------|--------|
| Engine Switch (Klipper/Kalico/RatOS) | ✅ |
| UFW Firewall | ✅ |
| SSH Hardening | ✅ |
| Log2Ram | ✅ |
| Auto-Restart | ✅ |
| Quick CAN Setup | ✅ |
| KATANA-FLOW | ✅ |
| Happy Hare | ✅ |
| Smart Probes | ✅ |
| Printer Config Wizard | ✅ |

## [v1.5-beta] - 2026-02-14

### Added
- **Initial beta release**
- Basic Klipper/Moonraker installation
- Mainsail/Fluidd deployment
- Crowsnest webcam support

### Added
- **HORIZON UI (Production Release)**:
  - Complete React-based web interface replacing Mainsail/Fluidd
  - Dashboard with live Toolhead, Thermals, Webcam, Print Progress
  - Console with real GCode communication via Moonraker WebSocket
  - FileManager with Upload, Delete, Print functionality
  - Job History panel
  - **Toolchanger Support** - Multi-tool UI (Dual/Quad Extruder)
  - **Timelapse Viewer** - Watch and manage timelapses
  - **Visual Layer Progress** - Enhanced print progress with layer visualization
  - **Config Diff Tool** - Compare config changes
  - Macros Panel - List and execute Klipper macros
  - Settings Panel with Dark/Light theme switcher
  - Diagnostics Panel with Support Bundle download
  - Service Health monitoring
  
- **Bash Installer Enhancements**:
  - Complete Uninstall function
  - Backup & Restore system
  - Update function for Klipper/Moonraker
  - Toolchanger setup (Quick/ERCF/Bondtech XTG/Custom)
  - Timelapse installation

### Changed
- Rebranded from "KATANA OFS" to "HORIZON"
- Modernized UI with cyber/techno aesthetic
- TypeScript for type-safe frontend code

### Features Differentiating from Mainsail/Fluidd
- Self-diagnosis and Auto-Repair
- Support Bundle Generator
- Config Diff Tool
- Visual Layer Progress
- Toolchanger UI (unique!)
- Full layout customization
- Dark/Light theme switching

## [v1.0.0-rc1] - 2026-02-13

### Added
- **HORIZON UI (Phase 2)**: 
  - Complete "Cyber/Techno" React-based web interface.
  - Replaces pure text-based installers with a visual dashboard.
  - **Modules**: Dashboard, Console, Files, Config, System.
- **Direct System Integration**:
  - `SystemHealth` Monitor: Real-time CPU, RAM, Disk usage.
  - `Auto-Healer`: One-click repair for common Klipper service issues.
- **Visual Configuration Editor**:
  - GUI for editing `printer.cfg` (Z-Offset, Pressure Advance, etc.).
  - "Unsaved Changes" protection.
- **Installer Enhancements**:
  - Automated Nginx deployment (`deploy_webui.sh`).
  - Service management via templates (`service_manager.sh`).
  - Preflight checks (`env_check.sh`).

### Changed
- Rebranded UI from "KATANA OFS" to "HORIZON".
- Integrated `deploy_webui.sh` into the main `install_ui.sh` flow.

### Fixed
- React build process optimized for production.
- TypeScript errors in UI components resolved.

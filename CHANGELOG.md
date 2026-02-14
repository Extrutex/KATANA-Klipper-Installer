# Changelog

All notable changes to this project will be documented in this file.

## [v1.0.0] - 2026-02-14

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

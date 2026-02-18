# KATANAOS v2.5 — MCU Persistence Update

## New Features
- **[MAJOR] MCU Board Registry:** "The Forge" now allows you to save board configurations after building.
  - **Save Config:** Stores your `menuconfig` settings and Flash Method preference.
  - **Batch Update:** New menu option "Update All Saved MCUs" rebuilds and flashes ALL your stored boards in one go.
  - **Storage:** Configs are saved in `~/printer_data/config/katana_boards/` (included in backups).

## Bug Fixes
- **v2.4.2 Included:** CAN persistence fix (`ifupdown`) and CAN menu fix (`can_manager.sh`) are included.

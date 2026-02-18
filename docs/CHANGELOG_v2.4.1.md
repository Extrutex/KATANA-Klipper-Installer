# KATANAOS v2.4.1 — Hotfix

## Bug Fixes
- **[CRITICAL] CAN-Bus Menu (Settings -> 4):** Fixed "command not found" error by sourcing the correct `can_manager.sh` module in `katanaos.sh`.
- **[CLEANUP] Deleted Dead Code:** Removed `modules/hardware/canbus.sh` (legacy file).

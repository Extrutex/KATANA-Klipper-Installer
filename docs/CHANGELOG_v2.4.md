# KATANAOS v2.4 — Security & Flow Update

## 🛡️ Security Hardening (Audit Phase 4)
- **[CRITICAL] Zip Traversal Fix:** Backups now extract relative to `$HOME` (previously `/`), mitigating overwrite risks (KAT-SH-001).
- **[HIGH] Supply Chain Safety:** Removed `curl | bash` piping. Node.js is now installed via verified GPG key + signed apt repository (KAT-SH-002).
- **[MED] Multi-User Support:** Replaced hardcoded `pi:pi` ownership with `$USER:$USER`. Codebase now runs on standard Debian/Armbian users (KAT-SH-005).
- **[MED] Robustness:** Fixed `medic.sh` zip logic and `logging.sh` eval documentation.
- **[LOW] Shell Hygiene:** Eliminated `ls` parsing in favor of robust glob arrays.

## 🌊 KATANA Flow (New Feature)
- **Smart Park:** Object-based parking *without* retraction (keeps nozzle primed).
- **X-Blade Purge:** New "Cross-Pattern" purge line for better nozzle wiping.
- **Micro-Macros:** Separated into `flow_start.cfg`, `flow_park.cfg`, `flow_purge.cfg`, `flow_end.cfg`.
- **Removed:** Legacy KAMP-style macros (`smart_purge.cfg`, `smart_park.cfg`).

## ⚔️ The Forge (Improvements)
- **Auto-Detection:** Improved DFU and Serial detection logic.
- **Safety Lock:** RP2040 boards are restricted to `.uf2` flashing (no DFU) to prevent bootloader damage.
- **Artifact Selection:** Flash method is now determined by the build artifact (`.uf2` vs `.bin`) rather than user choice.

## 📚 Documentation
- **Standardization:** All internal `.agent` documentation (Rules, Skills, Workflows) is now fully **English**.
- **Transparency:** "Source of Truth" rules updated with new security constraints.

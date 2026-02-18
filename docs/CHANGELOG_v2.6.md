# Changelog v2.6

## 🎨 User Interface Overhaul
- **[NEW] Pixel-Perfect Alignment:** The main menu and sub-menus have been redesigned for cleaner alignment.
- **[NEW] Responsive Padding:** Added `visible_len` and `make_pad` utilities to handle color codes and character widths correctly.
- **[FIX] ASCII Art:** Centered the KATANA logo properly within the 70-column frame.
- **[FIX] Version Display:** Moved version number to the bottom right for better aesthetics.

## Core
- **[FIX] Variable Conflict:** Renamed internal `VERSION` variable to `KATANA_VERSION` to avoid conflict with `/etc/os-release` (fixing the "13 triexie" bug).

## Documentation
- **[UPDATE] README.md:** Updated version references and toolhead guide.

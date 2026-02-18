# KATANAOS v2.4.2 — Hotfix

## Bug Fixes
- **[CRITICAL] CAN-Bus Persistence (Bookworm):** Added automatic installation of `ifupdown` package. Modern RPi OS images lack this by default, which prevented `auto can0` and `ifup` from working.
- **[Robustness] CAN Activation:** Improved manual activation logic (`ip link set ...`) if `ifup` fails or is not yet configured.

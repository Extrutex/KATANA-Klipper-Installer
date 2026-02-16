---
trigger: always_on
---

# Architekturregeln (KATANA)

## Zielbild
KATANA ist ein Installer + Orchestrator für Klipper-Stacks.
Moonraker bleibt die API-Basis.
Optional: Nginx, optional: React Web UI.

## Prinzipien
1. **Idempotenz**
   - Jeder Install-Step prüft State → ändert nur wenn nötig.
2. **Modularität**
   - Komponenten sind getrennt: klipper / moonraker / nginx / webui.
3. **Single Source of Truth**
   - Konfigurationen liegen zentral und nachvollziehbar (keine versteckten Defaults).
4. **Reparierbarkeit**
   - Diagnose + Repair sind gleichwertige Features wie Install.
5. **Keine Magie**
   - Jede Änderung ist logbar und rückverfolgbar.

## Empfohlene Standardpfade
- Code/Repos: `/opt/katana/<component>`
- Config: `/etc/katana/`
- Runtime/State: `/var/lib/katana/`
- Logs: `/var/log/katana/`

## systemd Konventionen
- Units: `katana-<component>.service`
- enable/start/restart klar definiert
- journald wird unterstützt (zusätzlich File-Logs optional)


## Modulaufteilung

- core
  - preflight
  - logging
  - state detection
  - locks

- components
  - klipper
  - moonraker
  - nginx
  - webui

- system
  - systemd
  - apt
  - filesystem
  - diagnostics
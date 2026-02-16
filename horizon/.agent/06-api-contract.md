---
trigger: always_on
---

# API Contract (Moonraker-only)

## Entscheidung
Moonraker bleibt die zentrale API-Schicht.
KATANA ist Installer/Orchestrator, kein API-Ersatz.

## Pflicht-Endpunkte (für UI/Tools)
- `server.info`
- `printer.info`
- `printer.objects.query`
- `machine.system_info`
- `machine.proc_stats`
- `server.files.*` (list/upload/metadata)
- Websocket API (Events)

## Stabilitätsregeln
- Moonraker Version ist zu dokumentieren (für reproduzierbare Setups).
- Vor Änderungen an Moonraker-Konfig:
  - Backup erstellen
  - Validierung/Repair anbieten

## UI Integration
- React UI spricht Moonraker direkt.
- Live-Updates via Websocket; fallback ggf. Polling (dokumentiert).

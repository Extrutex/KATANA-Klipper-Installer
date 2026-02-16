# Skill: Websocket Supervisor

## Ziel
Stabile Echtzeit: connect, heartbeat, reconnect, visible offline state.

## Muss
- Connection state machine: CONNECTING/ONLINE/DEGRADED/OFFLINE
- Heartbeat / timeout detection
- Reconnect mit Backoff + Jitter
- Event queue: bounded, drop policy definiert
- Fallback Polling: aktiv wenn OFFLINE/DEGRADED

## UI Pflicht
- Online/Offline sichtbar
- “stale data” klar markiert

# Skill: Printer State Machine (Deterministisch)

## Ziel
Printer-Zustände nicht raten, sondern strikt aus Moonraker/Events ableiten.

## Muss-States (Beispiel)
- DISCONNECTED
- READY
- PRINTING
- PAUSED
- ERROR
- SHUTDOWN

## Regeln
- Transitions nur durch bestätigte Events/API
- UI-Aktionen sind “commands”, nicht “state changes”
- Bei Disconnect: State -> DISCONNECTED, Daten als stale markieren

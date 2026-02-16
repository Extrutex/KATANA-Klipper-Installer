---
trigger: always_on
---

# No-Assumption Rule (No Hallucination Policy)

## Grundsatz

HORIZON und KATANA dürfen niemals:

- API Endpunkte annehmen
- Status ableiten ohne Validierung
- Services als „running“ anzeigen ohne echten Check
- Printer-State erraten
- Websocket Events simulieren
- Fehler maskieren

Alles muss durch echte Runtime-Daten validiert sein.

---

## Moonraker Kommunikation

- Nur dokumentierte API Calls verwenden.
- Websocket-Verbindung muss überwacht werden.
- Disconnect muss sichtbar sein.
- Fehler dürfen nicht still verschluckt werden.

---

## UI State

- UI darf niemals einen Zustand anzeigen,
  der nicht durch API oder Event bestätigt wurde.
- Kein optimistic state ohne Fallback.

---

## Service Status

- systemd Status muss geprüft werden.
- Port-Bindings müssen real validiert werden.
- Keine Annahme basierend auf Config-Dateien.

---

## Fehlerdarstellung

- Errors dürfen nicht versteckt werden.
- Jeder Fehler bekommt:
  - Source
  - Timestamp
  - Category
  - Details

---

## Priorität

Diese Regel hat höhere Priorität als:
- UI Schönheit
- Animation
- Refactoring
- Feature-Schnelligkeit

Korrektheit > Optik
Validierung > Annahme

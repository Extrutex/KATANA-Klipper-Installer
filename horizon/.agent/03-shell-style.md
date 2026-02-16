---
trigger: always_on
---

# Shell Styleguide (nur für NEUEN Code)

WICHTIG:
Diese Style-Regeln gelten primär für **neuen** Shell-Code.
Bestehende KATANA-Shell-Skripte dürfen nicht refactored werden.
Siehe: `04-existing-shell-protection.md`.

## Ziel
Neuer Code soll robust, testbar und lesbar sein.

## Empfehlungen
- klare Funktionen (Inputs/Outputs)
- konsistentes Logging (info/warn/error)
- defensive Checks vor Aktionen
- Backups mit Timestamp
- klare Rückgabewerte / Exit Codes

## Verboten (für neuen Code)
- unquoted vars
- stilles Ignorieren von Fehlern
- riskante "one-liner" ohne Checks

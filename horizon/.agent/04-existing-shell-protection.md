---
trigger: always_on
---

# Schutzregel: Bestehende Shell-Skripte dürfen nicht refactored werden

## Zweck
Die vorhandenen Shell-Skripte im KATANA Repository sind funktional.
Stabilität hat Vorrang vor Stil.

## Verboten
- Funktionen umbenennen
- Variablen umbenennen
- Menü-/Flow-Struktur verändern
- Codeblöcke umsortieren
- “Cleanups/Modernisierung” ohne echten Bugfix
- kosmetische Refactors

## Erlaubt
- neue Funktionen hinzufügen
- neue Features hinzufügen (additiv)
- zusätzliche Guards/Checks ergänzen
- zusätzliche Logs ergänzen
- Diagnose-/Repair-Routinen ergänzen

## Ausnahme (nur wenn zwingend)
Eine strukturelle Änderung am bestehenden Code ist nur erlaubt wenn:
1) ein realer Bug existiert
2) Änderung minimal-invasiv ist
3) Testplan dokumentiert wird
4) kein Verhalten unbeabsichtigt geändert wird

## Priorität
Diese Regel überschreibt Style-Optimierungen.
Stabilität > Eleganz

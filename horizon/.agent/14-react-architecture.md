# Skill: React Architecture (HORIZON)

## Ziel
Modular, testbar, performance-stabil.

## Muss
- core/api (Moonraker Client)
- core/ws (Supervisor)
- core/state (typed store, event-driven)
- modules/ (dashboard, console, files, jobs, settings, errors)
- components/ (shared)
- theme/ (design system)

## Performance
- virtualized lists (files/logs)
- memoization wo sinnvoll
- events bounded (no infinite growth)

## UI Pflicht
- responsive
- dark mode
- translations
- accessibility
- Lila Farben
- türkis Farben
- weiß Farben


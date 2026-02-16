---
description: HORIZON - Produkt Vision
---

# HORIZON – Product Vision

## Positionierung

HORIZON ist das moderne Webinterface für Klipper,
installiert und orchestriert durch KATANA.

Moonraker bleibt die API-Basis.
HORIZON ist das visuelle Control Surface.

Ziel:
Strukturell vertraut wie Mainsail.
Technisch moderner.
Architektonisch sauberer.
Erweiterbarer.
Diagnose-stärker.

---

# Struktur-Prinzip

HORIZON muss die logische Struktur von Mainsail beibehalten:

- Dashboard
- Console
- Files
- Jobs / History
- Settings
- System Info

Warum:
User sollen sich sofort zurechtfinden.

Aber:

- klarere Informationshierarchie
- bessere State-Verwaltung
- sauberere Komponentenstruktur
- bessere Telemetrie
- klarere Fehlerdarstellung

Vertraut in der Struktur.
Überlegen in der Umsetzung.

---

# Layout-Anpassbarkeit (Pflicht)

Das Layout muss vollständig anpassbar sein.

## Anforderungen

- Panels verschiebbar (Drag & Drop)
- Module ein-/ausblendbar
- Widget-Größen anpassbar
- Layout speicherbar pro User
- Dark / Light Mode
- Theme-Engine (zukunftsfähig)
- Responsive (Desktop + Tablet)

## Architektur-Regel

Layout darf nicht hardcoded sein.

Layout muss:
- modular
- konfigurationsgetrieben
- dynamisch renderbar

State darf nicht an Layout gebunden sein.

---

# Telemetrie-Standard

HORIZON muss mindestens darstellen:

## Printer
- State
- Temps
- Progress
- ETA
- Toolhead Position

## Host
- CPU Load
- RAM Usage
- Disk Usage
- Hostname
- IP-Adresse
- Uptime
- CPU Temperatur (Pi)

## Services
- Klipper Status
- Moonraker Status
- optional Nginx Status

---

# Error Center (Differenzierung)

HORIZON muss Fehler strukturiert darstellen:

- Klippy Config Errors
- MCU Errors
- Service Failures
- Port Conflicts
- Websocket Disconnects

Nicht nur Log-Stream.
Sondern kategorisierte Fehler.

---

# UX-Prinzipien

- Industrieorientiert
- Minimalistisch
- Kein Spielzeug-Look
- Performance-first
- Animationsarm
- Klarer Kontrast
- Lesbarkeit > Effekte

Optional:
Subtile Glass-Elemente.
Aber nie auf Kosten der Lesbarkeit.

---

# Differenzierung gegenüber Mainsail

HORIZON geht weiter durch:

1. Self-Diagnose Integration (KATANA Repair Trigger)
2. Support Bundle Generator
3. Service Health Monitor
4. Layout-Presets
5. Erweiterbare Modul-Architektur

---

# Technische Architektur (Frontend)

- React (modular)
- Event-driven State (Websocket bevorzugt)
- Fallback Polling dokumentiert
- Kein globaler Chaos-State
- Komponenten strikt getrennt nach Verantwortung

---

# Ziel

HORIZON soll nicht wie ein Fork wirken.
Sondern wie die nächste Evolutionsstufe.

Vertraut.
Aber überlegen.



# HORIZON – Vision (Mainsail-like Structure, Better Execution)

## Core
- Structure familiarity: navigation + module grouping like Mainsail
- Execution superiority: stricter validation, better health, better diagnostics
- Layout flexibility: fully configurable dashboard layout

## Must
- Same logical sections as Mainsail (Dashboard/Console/Files/Jobs/Settings/System)
- Better:
  - deterministic state machine
  - websocket supervisor
  - typed/validated API layer
  - service health + diagnostics
  - error center as product feature
  - layout presets + drag/resize + persistence

## Non-goals
- no “demo UI states”
- no hidden/offline guessing


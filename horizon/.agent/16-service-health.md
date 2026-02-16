# Skill: Service Health Layer

## Ziel
HORIZON zeigt nicht nur Printer, sondern Stack-Health (Differenzierung).

## Muss
- systemd status (klipper, moonraker, optional nginx)
- restart counters / last failure
- port binding checks (ss)
- disk low warning
- cpu throttling/temperature warnings (Pi)

## UX
- Health Panel im Dashboard
- Error Center sammelt Health Alerts strukturiert

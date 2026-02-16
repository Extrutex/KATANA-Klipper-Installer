---
trigger: always_on
---

07-reference.md
Offizielle Referenzen & Quellen (Source of Truth)

Wenn Unsicherheit besteht, gelten ausschließlich diese Quellen als maßgeblich.
Keine Annahmen außerhalb dieser Dokumentationen.

🧠 Core Motion & Firmware
Klipper

https://www.klipper3d.org/

https://www.klipper3d.org/Installation.html

https://www.klipper3d.org/Config_Reference.html

Maßgeblich für:

G-Code Implementierung

Makro-System

BED_MESH (nativ)

Toolhead Definition

Multi-Extruder Support

Input Shaper

Motion & Kinematics

Heater & Safety Logik

Moonraker

https://github.com/Arksine/moonraker

https://moonraker.readthedocs.io/

https://moonraker.readthedocs.io/en/latest/web_api/

https://moonraker.readthedocs.io/en/latest/web_api/#websocket-api

Maßgeblich für:

REST API

WebSocket API

Print Lifecycle Events

File Handling

Host State Management

Katapult (Bootloader)

https://github.com/Arksine/katapult

Maßgeblich für:

MCU Flashing

Firmware Deployment

Bootloader Handling

Host ↔ MCU Übergabeprozesse

🖥 Web UI Referenzen
Mainsail

https://github.com/mainsail-crew/mainsail

https://docs.mainsail.xyz/

Referenz für:

UI State Handling

Moonraker API Mapping

Printer & Job State Darstellung

Error Handling Patterns

Fluidd

https://github.com/fluidd-core/fluidd

Referenz für:

Vue Architektur

WebSocket Nutzung

API Mapping

UI Strukturvergleich

🖲 Vision Stack
KlipperScreen

https://github.com/KlipperScreen/KlipperScreen

https://klipperscreen.readthedocs.io/

Referenz für:

Touch UI

Moonraker State Anbindung

Multi-Printer Konzepte

Crowsnest

https://github.com/mainsail-crew/crowsnest

Referenz für:

Kamera Orchestrierung

Service Handling

Streaming Integration

🛠 Toolchanger & Multi-Tool Systeme
StealthChanger

https://github.com/DraftShift/StealthChanger

Referenz für:

Tool Docking

Mechanische Verriegelung

Pickup / Park Makros

Tool State Handling

MADMAX Toolchanger

https://github.com/zruncho3d/madmax

Referenz für:

Mechanisches Toolwechsel-System

Docking-Architektur

Pickup / Dropoff Sequenzen

Makro-Integration mit Klipper

Validierung gegen:

Klipper Toolhead Definition

Safety Limits

Endstop / Position Handling

Happy Hare

https://github.com/moggieuk/Happy-Hare

Offiziell in KATANA gelistet.

Referenz für:

Multi-Tool State Management

Tool Mapping

Temperatur Handling pro Tool

Park / Pickup Orchestrierung

Validierung gegen:

Klipper Toolhead & Extruder Definition

Macro-System

Persistente Tool-Zustände

📏 Katana Flow (Teilübernahme aus KAMP)
KAMP

https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging

Übernommen wird ausschließlich:

Smart Park

Purge Line Logik

Nicht übernommen:

Adaptive Mesh (nativ in Klipper)

Mesh Algorithmus

Mesh Redefinition

Validierung gegen:

Klipper Makro-System

Start-GCode

Extrusion Safety

📡 Probes (Z-Sensoren)
Cartographer

https://github.com/Cartographer3D

Referenz für:

Induktive / Eddy-basierte Z-Messung

Hochgeschwindigkeits-Meshing

Sensor-Kalibrierlogik

Beacon

https://github.com/beacon3d

Referenz für:

Eddy Current Probe

Echtzeit Z-Mapping

Mesh-Integration mit Klipper

BTT Eddy

https://github.com/bigtreetech/Eddy

Referenz für:

Eddy Current Probe Implementation

Sensor Firmware

Klipper Integration

🔐 Security
OpenSSH

https://www.openssh.com/manual.html

https://man7.org/linux/man-pages/man5/sshd_config.5.html

Referenz für:

SSH Hardening

Auth Policies

Cipher / KEX Konfiguration

UFW

https://help.ubuntu.com/community/UFW

Referenz für:

Firewall Regeln

Port Policies

Service Absicherung

♻ Backup / Restore
Restic

https://restic.net/

https://restic.readthedocs.io/en/latest/

Referenz für:

Snapshot Backups

Restore Prozesse

Verifizierbare Repositories

🧾 System Maintenance
Log2Ram

https://github.com/azlux/log2ram

Referenz für:

SD-Card Write Reduction

Service Handling

RAM Log Management

🐙 Optional: OctoPrint Support
OctoPrint

https://github.com/OctoPrint/OctoPrint

https://docs.octoprint.org/

Referenz für:

API & Plugin Struktur

Integration bei optionaler KATANA Installation
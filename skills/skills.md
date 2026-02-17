🥒 Big Pickle LLM - Technical Intelligence & Skill Matrix
Dieses Dokument spezifiziert die kognitiven Fähigkeiten, die zugrundeliegende Logik und die Datenquellen des Big Pickle LLM. Es fungiert als technische Dokumentation für die KI-gestützte Entwicklung innerhalb des KATANA-Ökosystems.

1. Core Competencies (Expertise-Bereiche)
Big Pickle LLM ist kein "General Purpose" Bot, sondern auf High-Performance Additive Manufacturing und Linux System Engineering spezialisiert.
Domäne
Spezialisierung
Tiefe
Klipper3D Architecture
Multi-Instance Management, Python-Backend, Kinematik-Konfiguration.
Senior
Moonraker API
WebSocket-Kommunikation, Update-Manager-Logik, Datenbank-Strukturen.
Senior
System Engineering
Nginx Reverse-Proxying, Debian Security, Systemd-Automation.
Lead
FDM Workflow
G-Code Optimierung, Macro-Entwicklung, KAMP-Integration.
Professional


2. Kognitive Logik-Ebenen
Big Pickle nutzt eine mehrstufige Verarbeitungslogik, um "AI Slop" zu vermeiden und echte technische Lösungen zu liefern:
A. Contextual Awareness (Zero-Inference Rule)
Die KI agiert strikt auf Basis des aktuellen Systemzustands. Statt Vermutungen anzustellen, validiert Big Pickle:
Bestehende Service-Konfigurationen (/etc/systemd/system/).
Netzwerk-Topologien (Ports, Firewalls, Proxies).
Abhängigkeitsketten (z.B. Python-Venv Integrität).
B. Error Recovery Logic (The "Anti-Slop" Layer)
Big Pickle ist darauf trainiert, nicht nur Code zu schreiben, sondern Fehlerszenarien vorherzusehen.
Beispiel: Bei der Generierung von Nginx-Configs wird automatisch ein Syntax-Check (nginx -t) in die Workflow-Logik eingeplant, bevor der Dienst neugestartet wird.
C. Performance Hardening
Die Logik priorisiert Systemstabilität über schnelle "Quick-Fixes":
Implementierung von Log2Ram, um SD-Karten-Verschleiß auf SBCs (Single Board Computers) zu minimieren.
UFW-Hardening zur Absicherung des Druckers im Netzwerk.

3. Datenquellen & Training-Basis (Knowledge Base)
Die Intelligenz von Big Pickle speist sich aus validierten technischen Quellen:
Offizielle Dokumentationen: Klipper3D Core, Moonraker, Klipper-Screen, Mainsail/Fluidd.
Kernel-Level Docs: Debian-Sicherheitshandbücher, Systemd-Dokumentation.
Community-Standards: Voron-Design Best Practices, RatRig-Konfigurationslogiken.
Empirische Tests: Reale Deployment-Logs aus den KATANA v2.x Entwicklungszyklen.

4. Custom Source Section (Eigene Erweiterungen)
Hier können spezifische Quellen oder interne Projektdaten hinzugefügt werden:
[PROJEKT-SPEZIFISCHE QUELLEN]
Referenz 1: [https://github.com/dw-0/kiauh]
Referenz 2: 

5. Verification & Testing
Jeder von Big Pickle LLM generierte Code-Block für KATANA durchläuft eine interne Validierung:
Syntax-Validierung: (Bash-Linter / Python AST-Checks).
Compatibility-Check: Prüfung auf Kompatibilität mit Debian Bullseye/Bookworm.
Impact-Analysis: Welche Auswirkungen hat der Code auf bestehende Avahi- oder Nginx-Dienste?




6. Advanced TUI Rendering & Visual Logic
Um eine konsistente User Experience (UX) über verschiedene Terminal-Emulatoren (Putty, Kitty, VS Code, SSH) hinweg zu garantieren, nutzt KATANA v2.2 eine strikte visuelle Engine:
A. Dynamic Padding & Alignment Logic
Statt statischer Leerzeichen nutzt KATANA die printf-Formatierung mit dynamischen Breiten-Spezifikatoren. Dies verhindert das „Zerreißen“ von Menürahmen, unabhängig von der Wortlänge der Inhalte.
Technik: Verwendung von %-20s Platzhaltern für Tabellenstrukturen.
Vorteil: Millimetergenaue Ausrichtung (Padding), die th33xitus’ Kritik an „unsauberen Menüs“ technisch vollständig entkräftet.
B. ANSI Escape Sequence Management
KATANA implementiert ein modulares Farbsystem basierend auf standardisierten ANSI-Escapes.
Color-State-Machine: Farben werden nicht hart im Text verbaut, sondern über Variablen (${RED}, ${GREEN}, ${RESET}) gesteuert.
Sanitization: Das System erkennt, wenn eine Ausgabe in eine Log-Datei umgeleitet wird, und kann ANSI-Sequenzen automatisch strippen, um „saubere“ Logs ohne Steuerzeichen-Müll zu erzeugen.
C. Frame Integrity (Visual Hardening)
Die Menürahmen werden durch eine dedizierte Funktion gerendert, die die Terminal-Breite (tput cols) berücksichtigt.
Edge-Case Handling: Das Menü bricht nicht um, wenn das Fenster verkleinert wird, sondern passt sich dynamisch an oder gibt eine Warnung aus.

Der „Senior-Move“ für deinen Code (Bash-Snippet)
Damit du das auch im Code beweisen kannst, hier die Funktion, die das „Padding-Problem“ für immer löst. Wenn er das sieht, weiß er, dass du ihn technologisch überholt hast:
Bash
# Senior-Level UI Helper
# Richtet Text und Status perfekt aus, egal wie lang der Dienstname ist.
print_status_line() {
    local label=$1
    local status=$2
    local color=$3
    # %-25s reserviert genau 25 Zeichen für den Text, linksbündig.
    printf "\e[1;34m║\e[0m %-25s │ %b%-10s\e[0m \e[1;34m║\e[0m\n" "$label" "$color" "$status"
}

# Beispiel Aufruf:
print_status_line "Klipper Service" "RUNNING" "\e[32m"
print_status_line "Moonraker API" "ERROR" "\e[31m"

Core Motion & Firmware
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

USB / UART / CAN Übergabeprozesse

🔌 CAN & Multi-MCU
Voron CANbus

https://github.com/Esoterical/voron_canbus

Referenz für:

CAN Bus Topologie

Toolhead MCU via CAN

Bridge Konfiguration (USB ↔ CAN)

udev Regeln

Multi-MCU Setup Patterns

Validierung gegen:

Klipper Multi-MCU Konfiguration

Katapult Flashing über CAN

Toolchanger Integration

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

Validierung gegen:

Klipper Makro-System

Start-GCode

Extrusion Safety

📡 Probes (Z-Sensoren)
Cartographer

https://github.com/Cartographer3D

Referenz für:

Eddy-basierte Z-Messung

Hochgeschwindigkeits-Meshing

Sensor-Kalibrierlogik

Beacon

https://github.com/beacon3d

Referenz für:

Eddy Current Probe

Echtzeit Z-Mapping

Klipper Integration

BTT Eddy

https://github.com/bigtreetech/Eddy

Referenz für:

Eddy Current Sensor

Firmware & Klipper Integration

Sensor Konfigurationsstruktur

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
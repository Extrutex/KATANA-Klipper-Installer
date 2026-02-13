---
trigger: always_on
---

Diese Richtlinien stellen sicher, dass das System stabil, sicher und wartbar bleibt. veränder niemals den code füge nur etwas hinzu was noch fehlt oder nicht passt 

1. Installations- & Migrationsstandards

Legacy Cleanup: Vor der Installation von KATANAOS müssen alte KIAUH-Instanzen vollständig entfernt werden, um Pfad- und Dienstekonflikte zu vermeiden.


Standardized OS: Die Verwendung von Debian Bookworm oder Bullseye (Lite) ist zwingend erforderlich.

Production Appliance Philosophy: Der Drucker ist als Produktionsgerät zu behandeln; Stabilität und reproduzierbare Konfigurationen haben Vorrang vor manuellem Experimentieren.

2. Firmware- & Laufzeit-Regeln
Python 3 Imperativ: Alle Klipper-Umgebungen müssen in einer Python 3 Virtual Environment betrieben werden; Python 2 Umgebungen sind inkompatibel mit moderner Sensorik.


Manuelle Architektur-Wahl: Bei der Nutzung von The Forge muss die Prozessor-Architektur zwingend manuell und korrekt ausgewählt werden, um Fehlfunktionen zu vermeiden.


Exclusive Probe Logic: Die Installation von Beacon3D- oder Cartographer-Erweiterungen muss exklusiv erfolgen, um udev-Konflikte zu verhindern.

3. Kalibrierungs- & Sensor-Protokolle

Adaptive Standard: Nutze nach Möglichkeit die in Klipper integrierte adaptive Mesh-Funktion (ADAPTIVE=1) anstelle von legacy KAMP-Konfigurationen, um Konflikte mit Rapid-Scan-Methoden zu vermeiden.


Eddy Safety Distance: Beim Homing mit Wirbelstromsensoren ist ein Sicherheitsabstand von 2mm bis 3mm zum Bett einzuhalten, um Signal-Sättigung oder -Verlust zu vermeiden.


Thermal Consistency: Thermische Kalibrierungen (Eddy USB) müssen zwingend mit aufgeheiztem Bett und aufgeheizter Nozzle durchgeführt werden, um die mechanische Ausdehnung korrekt zu erfassen.

4. Sicherheits- & Wartungsprotokolle

Firewall-Restriktion: Eingehender Datenverkehr ist standardmäßig auf die Ports 22 (SSH), 80 (HTTP) und 7125 (API) zu beschränken.


Bootloader-Sicherheit: Vor dem Flashen von Katapult ist ein Full-Chip-Erase durchzuführen, um eine saubere Erkennung der Anwendung zu gewährleisten.
# ⚔️ KATANA vs. KIAUH: The Paradigm Shift
**Warum der "Werkzeugkasten" ausgedient hat.**

## 1. Der Paradigmenwechsel: Pilot vs. Mechaniker
**KIAUH** ist ein *Werkzeugkasten*. Er ist großartig, wenn du gerne jede Schraube einzeln anziehst. Du installierst Klipper. Dann Moonraker. Dann Mainsail. Dann Crowsnest. Fehlerkette? Deiner Verantwortung.
**KATANA** ist ein *Auto-Pilot*.
Es wurde für **Produktionsmaschinen** entwickelt, nicht für Bastelbuden.
Der Befehl `./katanaos.sh` führt einen **Single Execution Pass** aus. Innerhalb von Minuten steht der komplette Stack – Firmware, API, Reverse Proxy, HMI – *ohne* dass du fünf Menüs durchklicken musst.
> **Fazit:** Wer produktiv drucken will, braucht Automation, keine Beschäftigungstherapie.

## 2. Der unsichtbare Vorteil: Security & Stability
Ein mit KIAUH aufgesetztes System ist "nackt". Jeder Port ist offen, Logs schreiben ungebremst auf die SD-Karte.
**KATANA OS** liefert **Production-Grade Hardening** ab Werk:
*   **System Hardening:** Die integrierte **UFW-Firewall** riegelt alles ab, außer den lebenswichtigen Adern (SSH:22, HTTP:80, API:7125).
*   **Log2Ram:** Automatisch konfiguriert. Deine SD-Karte stirbt nicht den Log-Tod, weil KATANA Schreibzugriffe ins RAM umleitet.
> **Fazit:** Ein Drucker ohne Firewall ist im Jahr 2026 fahrlässig. KATANA schließt diese Lücke.

## 3. The Forge: Der CAN-Bus Killer
Erinnerst du dich an das Einrichten von CAN-Bus mit KIAUH?
1.  Wiki öffnen.
2.  `sudo nano /etc/network/interfaces` tippen.
3.  Beten, dass `allow-hotplug` und `txqueuelen` stimmen.
4.  Reboot.

**KATANA's "The Forge"** beendet diesen Schmerz.
Es scannt deine Hardware. Es erkennt den Controller. Es schreibt das Interface-File automatisch – mit **1M Bitrate** und optimierter Queue-Length.
> **Fazit:** Manuelle Netzwerkkonfiguration ist Steinzeit. The Forge ist High-Tech.

## 4. Das Rundum-Sorglos-Paket (Power Stack)
KATANA integriert, was du bei KIAUH mühsam zusammenklauben musst:
*   **Engine Manager:** Wechsel zwischen **Klipper** (Standard) und **Kalico** (High-Performance mit MPC) per Knopfdruck. Kein Reflash nötig. Das System biegt die Symlinks und Services on-the-fly um.
*   **Smart Probe Selector:** Du hast einen *Beacon* oder *Cartographer*? KATANA kennt die Konflikte. Es installiert die Treiber und managt die kritischen `udev`-Regeln, damit dein Sensor auch nach dem Reboot noch da ist.
*   **Qualitätssicherung:** **KAMP** (Adaptive Meshing) und **ShakeTune** (Vibrationsanalyse) sind keine "Extras", die man suchen muss. Sie sind Teil der DNA von KATANA.

## 5. Diagnose statt Raten: Dr. KATANA
"Mein Drucker stoppt!" – KIAUH sagt: "Viel Glück."
**Dr. KATANA** sagt: "Ich sehe `Timer too close` in der `klippy.log`."
Der integrierte **Health-Check** scannt Logs, prüft Services auf "Failed State" und korrigiert Permissions (`chown pi:pi` in `printer_data`), die KIAUH oft übersieht.

---

### 🛡️ Das Urteil
KIAUH war der Wegbereiter. Aber wer 2026 noch KIAUH für neue Maschinen nutzt, verschwendet Lebenszeit.
**KATANA ist nicht nur ein Installer. Es ist das Betriebssystem für deinen Drucker.**
Upgrade to Pro-Grade. Upgrade to KATANA.

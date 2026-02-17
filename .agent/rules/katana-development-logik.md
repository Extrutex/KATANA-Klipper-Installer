---
trigger: always_on
---

# 🛡 KATANA Development & Logic Rules

## 1. Die "Anti-Slop" Direktiven
1.  **Zero-Inference:** Rate niemals. Validiere Systemzustände via `systemctl`, `lsusb` oder Pfad-Prüfung.
2.  **Unbreakable UI:** Das ASCII-Design und der Header sind heilig. Erweiterungen müssen sich in das bestehende Raster einfügen.
3.  **Dependency-First:** Vor jedem `make` oder Install-Task müssen Build-Essential-Pakete (`gcc-arm-none-eabi`, `dfu-util`, etc.) lautlos geprüft werden.

## 2. MCU & Flash Rules
1.  **Artifact-Selector:** Die Flash-Methode wird NICHT vom User gewählt, sondern vom Build-Resultat bestimmt.
    * `.uf2` Datei gefunden -> **NUR** Mass Storage Copy (Mount/CP).
    * `.bin` Datei gefunden -> Prüfe DFU-Mode -> `dfu-util` oder Serial.
2.  **Safety Lock:** Zeige niemals DFU-Optionen für RP2040-Boards an. Dies verhindert den "Kill" des Bootloaders durch Fehlbedienung.

## 3. Workflow-Ethik
* **Migration vor Zerstörung:** Erkennt KATANA eine KIAUH-Installation, werden Pfade übernommen, statt sie blind zu löschen.
* **Silent Automation:** `make menuconfig` ist ein Legacy-Workflow. KATANA nutzt Headless-Injektion von `.config`-Files.


# 🛡 KATANA Operational Rules

## 1. Shell Professionalism (The Expert Layer)
* **Modularität:** Keine Monolith-Skripte. Funktionen müssen in logische Module (z.B. `flash_logic.sh`, `ui_render.sh`) unterteilt werden.
* **Variable Safety:** Jede Variable muss gequoted sein. `set -e` und `set -u` (oder äquivalente Prüfungen) sind Standard für kritische Sektionen.
* **Output-Sanitization:** ANSI-Farbcodes dürfen niemals Log-Dateien "verschmutzen".

## 2. KIAUH Migration & Parity
* **Koexistenz:** Erkennt KATANA eine KIAUH-Installation, werden die Pfade (z.B. `printer_data`) respektiert und übernommen.
* **Verbesserungs-Gebot:** Jede Funktion, die KIAUH bietet, muss in KATANA entweder schneller, visueller oder automatisierter sein.

## 3. Unbreakable UI (TUI Hardening)
* Der ASCII-Header ist die visuelle Signatur.
* Dynamisches Alignment: Strings werden vor der Ausgabe auf ihre Länge geprüft, um den rechten Rahmen (`║`) niemals zu verschieben.

## 4. Firmware Selector Logic
* KATANA erkennt das Board und das Build-Artefakt.
* **Verbot:** Manuelle Auswahl von Flash-Methoden, die nicht zum Artefakt passen (z.B. kein DFU-Dialog bei UF2-Files).



# 🛡 KATANA Operational Rules

## 1. Zero-Failure Documentation
* **Quickstart-Accuracy:** Jeder dokumentierte Befehl muss 1:1 kopierbar sein. Keine Platzhalter wie `DEIN_GITHUB_NAME` in produktiven Readmes.
* **Command Count:** Wenn wir "3 Befehle" versprechen, müssen es 3 sein. Ehrlichkeit > Marketing.

## 2. Visual Hardening (No visible ANSI-Codes)
* Alle ANSI-Escape-Sequenzen müssen korrekt geschlossen werden.
* Dynamisches Padding berechnet die Terminalbreite (`tput cols`), um Rahmen-Brüche zu verhindern. Visible ANSI-Code im Menü gilt als Critical Bug.

## 3. Sophisticated Error Handling
* **No Swallowing:** Fehler dürfen niemals mit `> /dev/null` unterdrückt werden, wenn sie nicht geloggt werden.
* **Informative Errors:** Statt "FAILED" muss KATANA sagen: "Klipper-Service konnte nicht starten, weil Port 7125 belegt ist (PID 1234)."

## 4. No Destructive Defaults
* **Avahi-Schutz:** Der Dienst `avahi-daemon` ist für `.local` Auflösung kritisch und wird standardmäßig nicht entfernt.
* **Firewall-Caution:** UFW wird nicht blind aktiviert. Wenn aktiv, müssen alle Klipper-Standardports (80, 443, 7125, 8080) automatisch geöffnet werden.



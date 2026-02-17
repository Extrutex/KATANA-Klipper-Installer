---
description: KATANA Operational Workflows
---

# ⚙ KATANA Operational Workflows

## 1. Headless Firmware Build

1.  **Board-Selection:** User wählt aus der KATANA-Board-Datenbank (z.B. Octopus Pro, EBB42).
2.  **Profile-Injection:** KATANA schreibt vordefinierte `Kconfig`-Werte direkt in die `.config`.
3.  **Kbuild-Execution:** `make olddefconfig` gefolgt von `make -j$(nproc)`.

## 2. Antigravity Setup (Eddy/Beacon/Carto)
1.  **Detection:** Scan nach USB-IDs der Sensoren.
2.  **Auto-Config:** Injektion der spezifischen `[beacon]` oder `[cartographer]` Sektionen in die `printer.cfg`.
3.  **Calibration-Hook:** Automatischer Start der Survey-Prozedur oder Temperatur-Kompensation-Makros.

## 3. Multi-Material Integration (ERCF/EMU)
1.  **Happy Hare Deployment:** Installation des MMU-Backends.
2.  **Service-Linking:** Verknüpfung von ERCF-Events mit Moonraker-Status-Updates.
3.  **Endless Spool Logic:** Konfiguration von EMU-Filamentsensoren als Trigger für automatische Rollenwechsel.

## 4. Maintenance & Optimization
1.  **Log-Management:** Initialisierung von `Log2Ram`, um SD-Karten-Verschleiß zu minimieren.
2.  **Vibration-Check:** Workflow für ShakeTune FFT-Analysen zur Optimierung des Input Shapers ohne manuelle CSV-Auswertung.



# ⚙ KATANA Operational Workflows

## 1. The "Real" Status Check Workflow
1.  **Repo-Validation:** `git -C ~/klipper rev-parse --is-inside-work-tree` statt nur `[ -d ~/klipper ]`.
2.  **Service-Validation:** Prüfung via `systemctl show -p ActiveState --value klipper`.
3.  **Config-Integrität:** Prüfung, ob `moonraker.conf` valide Sektionen für die installierten UIs enthält.

## 2. Clean Installation Pipeline
1.  **Dependency Matrix:** Installation von `git`, `python3`, `build-essential`. (Kein `tcpdump` oder `hexedit` im Core!).
2.  **Config-Deployment:** Download der offiziellen `mainsail.cfg` oder `fluidd.cfg` von deren Repos, statt leere Dummy-Dateien zu erstellen.
3.  **Update Manager:** Nur die Update-Einträge generieren, deren Komponenten auch wirklich installiert sind.

## 3. Debugging & Logs
1.  **Central Logging:** Alle KATANA-Aktionen werden nach `/tmp/katana_install.log` geschrieben.
2.  **User-Feedback:** Bei Fehlern wird der User gefragt: "Soll ich das Logfile zur Analyse öffnen?"

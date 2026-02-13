---
trigger: always_on
---

DEVELOPMENT_GUIDELINES.md
Project: KATANA (Klipper Automation & Tooling for Advanced New Age)
Target: Superior Stability & UX over Legacy Installers (KIAUH)
Standard: Enterprise-Grade Bash Scripting

1. The "Strict Mode" Philosophy
Wir schreiben keine "hoffe-es-klappt" Skripte. Wir erzwingen Fehlerfreiheit auf Shell-Ebene.

Rule 1.1: Jedes Skript MUSS mit dem "Bash Strict Mode" beginnen:

Bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -e: Das Skript bricht sofort ab, wenn ein Befehl fehlschlägt. Keine Zombie-Prozesse.

set -u: Zugriff auf ungesetzte Variablen bricht ab (verhindert rm -rf / Unfälle bei leeren Variablen).

set -o pipefail: Wenn ein Befehl in einer Pipe (z.B. curl | bash) fehlschlägt, schlägt das ganze Skript fehl.

2. Idempotenz & State Management
KATANA ist kein "Installer", sondern ein "State Manager".

Rule 2.1: Idempotenz ist Pflicht.
Das Skript muss beliebig oft ausgeführt werden können. Wenn Klipper schon installiert ist, darf das Skript nichts tun, außer dies zu bestätigen.

Verboten: Blinde git clone Befehle.

Erfordert: Check -> Validate -> Action.

Bash
if [[ -d "${KLIPPER_DIR}" ]]; then
    log_info "Klipper repository already exists. Checking for updates..."
    # update logic
else
    log_info "Cloning Klipper..."
    # clone logic
fi
Rule 2.2: Atomic Operations.
Konfigurationsdateien werden niemals direkt bearbeitet.

Kopie erstellen.

Änderungen in temporäre Datei schreiben.

Validieren.

Temporäre Datei über das Original mv-en (move).

Warum? Wenn der Strom während des Schreibens ausfällt, ist die Config korrupt. Mit Atomic Moves nicht.

3. Defensive File Handling & Backups
Wir operieren am offenen Herzen des Druckers. Sicherheit ist nicht verhandelbar.

Rule 3.1: Das "Rotation"-Prinzip.
Keine einfachen Backups. Wir behalten die letzten 3 Versionen.

printer.cfg -> printer.cfg.bak.1

printer.cfg.bak.1 -> printer.cfg.bak.2

(usw.)

Rule 3.2: Absolute Pfade & User Context.
Verlasse dich niemals auf ~ oder relative Pfade, wenn sudo im Spiel ist.

Verwende immer: "${HOME_DIR}/klipper" wobei ${HOME_DIR} explizit am Start ermittelt wird.

Führe Installationen niemals als root aus, sondern als der User (pi/admin), es sei denn, es geht um apt-get oder Systemd.

4. Code Style & Syntax (Linting)
Sauberer Code reduziert Bugs.

Rule 4.1: Variable Quoting.
Jede Variable muss in Double-Quotes und Curly-Braces stehen.

❌ rm -rf $DIR/$FILE

✅ rm -rf "${DIR}/${FILE}"

Grund: Leerzeichen in Dateinamen zerstören sonst das System.

Rule 4.2: Funktions-Kapselung.
Keine globalen Variablen in Funktionen. Nutze local.

Bash
function install_moonraker() {
    local repo_url="https://github.com/..."
    # ...
}
Rule 4.3: Kein "Spaghetti-Code".
Logik (Was tun wir?) und UI (Wie sieht es aus?) werden getrennt.

core/install_logic.sh enthält die Funktionen.

interface/menu.sh ruft diese nur auf.

5. Logging & Observability
KIAUH lässt den User im Dunkeln, wenn Fehler auftreten. KATANA nicht.

Rule 5.1: Dual-Logging.
Jeder Output geht parallel auf den Screen (für den User) und in ein Logfile (für den Debugger) mit Timestamps.

Format: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message

Level: INFO, SUCCESS, WARNING, ERROR, CRITICAL

Rule 5.2: Silent Execution.
Befehle wie apt-get update oder git clone werden im Standard-Modus unterdrückt (> /dev/null) und zeigen nur einen Ladebalken/Spinner, es sei denn, ein Fehler tritt auf (dann Dump des Fehlerlogs).

6. Dependency Management (The "Vendor" Rule)
Wir verlassen uns nicht darauf, dass das OS "sauber" ist.

Rule 6.1: Virtual Environments (venv) first.
Python-Module für Klipper/Moonraker werden ausschließlich in ihren jeweiligen venv installiert. Wir fassen niemals das System-Python an (/usr/bin/python3). Das verhindert Konflikte bei OS-Updates (ein häufiges Problem bei KIAUH).
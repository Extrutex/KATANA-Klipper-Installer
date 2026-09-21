#!/usr/bin/env bash
# --- CRLF GUARD (issue #1) ---
# Windows line endings (git autocrlf / ZIP download) make bash fail with
# cryptic errors ("$'\r': command not found"). Detect and explain instead.
# The check MUST stay on a single line ending in a comment: a multi-line
# if/then/fi does not parse once the file itself is CRLF (verified).
if [[ "$(head -c 200 "${BASH_SOURCE[0]}" | tr -d '\0')" == *$'\r'* ]]; then echo "ERROR: ${BASH_SOURCE[0]} has Windows line endings (CRLF) and cannot run." >&2; echo "Fix:   sed -i 's/\r\$//' ${BASH_SOURCE[0]}   (or re-clone after: git config --global core.autocrlf false)" >&2; exit 1; fi  # single line by design: must parse even when this file is CRLF

################################################################################
#  ⚔️  KATANAOS - THE KLIPPER BLADE v2.6 (B2B Refactored)
# ------------------------------------------------------------------------------
#  PRO-GRADE KLIPPER INSTALLATION & MANAGEMENT SUITE
#  Modular Architecture | Native Flow | Bulletproof Error Handling
################################################################################

# --- EXECUTION MODE ---
# pipefail: Verhindert dass Pipe-Fehler verschluckt werden.
#
# `set -e` and `set -u` are deliberately NOT enabled at this level, and the
# omission is documented rather than silent:
#
#   -e  this file sources ~30 legacy modules and then runs an interactive menu
#       loop. In that tree an unchecked non-zero return is routine (a cancelled
#       submenu, a `grep` with no match), and aborting the whole tool on one
#       would be a regression, not a hardening.
#   -u  the module tree still references undefined colour variables
#       (e.g. C_YELLOW in core/dispatchers.sh, which logging.sh does not
#       define). With -u the tool would die mid-render. Cleaning that up is a
#       separate change with its own review surface.
#
# Strictness is applied where it can be verified instead of hoped for: every
# unattended install step runs under `set -euo pipefail` in its own subshell
# (see headless_run_step in core/headless.sh), and the executed entrypoint
# install.sh enables all three.
set -o pipefail

# --- VERSION ---
readonly KATANA_VERSION="v2.6"
readonly BUILD="2026-02-24"

# Setze Terminal für korrekte UI-Darstellung
export TERM=xterm-256color

# --- CONSTANTS & PATHS ---
# Dynamischer Workspace-Pfad für maximale Portabilität
export KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CORE_DIR="$KATANA_ROOT/core"
export MODULES_DIR="$KATANA_ROOT/modules"
export CONFIGS_DIR="$KATANA_ROOT/configs"
export LOG_FILE="$KATANA_ROOT/katana.log"

# --- HATCH RESOLUTION (Firmware/Board-Authority — see hatch/README once extracted) ---
# HATCH resolution order:
#   1. Embedded hatch/ (present in this repo, preferred when hatch/hatch.sh exists)
#   2. External repo via KATANA_HATCH_REPO_DIR env variable (set before calling katanaos.sh)
#   3. Managed install at ~/.local/share/katana/hatch (auto-cloned by a future hatch_runtime.sh)
# When HATCH is extracted to its own repo, set KATANA_HATCH_PROVIDER_MODE=external
# and KATANA_HATCH_REPO_DIR=/path/to/HATCH — no other change needed here.
_HATCH_EMBEDDED="$KATANA_ROOT/hatch"
_HATCH_EXTERNAL="${KATANA_HATCH_REPO_DIR:-}"
_HATCH_MANAGED="$HOME/.local/share/katana/hatch"

if [[ -f "$_HATCH_EMBEDDED/hatch.sh" && "${KATANA_HATCH_PROVIDER_MODE:-auto}" != "external" ]]; then
    HATCH_DIR="$_HATCH_EMBEDDED"
elif [[ -n "$_HATCH_EXTERNAL" && -f "$_HATCH_EXTERNAL/hatch.sh" ]]; then
    HATCH_DIR="$_HATCH_EXTERNAL"
elif [[ -f "$_HATCH_MANAGED/hatch.sh" ]]; then
    HATCH_DIR="$_HATCH_MANAGED"
else
    HATCH_DIR=""
fi
export HATCH_DIR

# --- PROFILE HANDLER ---
# Standardprofil, überschreibbar via CLI
INSTALL_PROFILE="standard"
export INSTALL_PROFILE


# ==============================================================================
# 1. ERROR HANDLING & VALIDATION
# ==============================================================================

# Globaler Error Trap: Faengt unerwartete Abstuerze waehrend der LADEPHASE ab.
#
# Scope note, because both productive paths switch this off further down and
# that reads like an oversight: this trap covers the window between here and
# main() — sourcing the core and optional modules, and argument parsing. In
# that window any non-zero status really is unexpected and aborting is right.
#
# It is NOT the error handling of the two productive paths:
#   - the unattended path replaces it with checked returns and per-step
#     `set -euo pipefail` (see main(), and headless_run_step in core/headless.sh)
#   - the interactive loop replaces it with per-command log_error, because a
#     submenu returning 1 (a cancelled install) must not kill the session
# Both are argued at their respective `trap - ERR`.
error_trap() {
    local exit_code=$?
    local line_no="${1:-?}"
    echo -e "\n\033[38;5;196m[CRITICAL ERROR] Das Skript ist unerwartet in Zeile ${line_no} mit Exit-Code ${exit_code} abgestürzt!\033[0m" >&2
    echo "Bitte überprüfe die Log-Datei: ${LOG_FILE:-<nicht gesetzt>}" >&2
    exit "$exit_code"
}
trap 'error_trap $LINENO' ERR

# Überprüft, ob ein essentielles Modul existiert, bevor es geladen wird
require_module() {
    local module_path="$1"
    if [[ ! -f "$module_path" ]]; then
        echo -e "\n\033[38;5;196m[FEHLER] Kritisches Systemmodul fehlt: ${module_path}\033[0m"
        echo "Bitte überprüfe, ob das Repository vollständig heruntergeladen wurde."
        exit 1
    fi
    source "$module_path"
}


# ==============================================================================
# 2. CLI ARGUMENT PARSER
# ==============================================================================

show_help() {
    echo "KATANAOS $KATANA_VERSION - Usage:"
    echo ""
    echo "  ./katanaos.sh                     Startet das interaktive Menü"
    echo "  ./katanaos.sh install [OPTIONEN]  Unbeaufsichtigte Installation"
    echo "  ./katanaos.sh --version           Zeigt die Version an"
    echo "  ./katanaos.sh --help              Zeigt diese Hilfe an"
    echo ""
    echo "  Optionen:"
    echo "    --profile <p>   minimal | standard | power   (Default: standard)"
    echo "    --ui <u>        mainsail | fluidd | none     (Default: mainsail)"
    echo "    --yes, -y       Ohne Rueckfrage installieren (fuer 'install' Pflicht)"
    echo "    --dry-run       Nur den Plan ausgeben, nichts veraendern"
    echo ""
    echo "  Beispiele:"
    echo "    ./katanaos.sh install --profile standard --dry-run"
    echo "    ./katanaos.sh install --profile minimal --ui none --yes"
    echo ""
    echo "  Exit-Codes: 0 ok | 1 Schritt fehlgeschlagen | 2 Aufruf falsch |"
    echo "              3 --yes fehlt"
    echo ""
}

# Parses the whole command line, not just $1. The previous version inspected
# one argument, so "--profile power --help" silently ignored --help and an
# unknown flag was accepted as if it had been understood — the worst failure
# mode for a tool meant to run unattended, because the script reports success
# for something it never did.
#
# Sets HEADLESS_* for main() to act on. Exits directly only for the flags that
# produce output and nothing else (--version, --help) or for a usage error.
HEADLESS_MODE=0
HEADLESS_UI="mainsail"
HEADLESS_CONFIRMED=0
HEADLESS_DRY_RUN=0

handle_args() {
    if [[ "${1:-}" == "install" ]]; then
        HEADLESS_MODE=1
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                if [[ -z "${2:-}" ]]; then
                    echo "Fehler: --profile benoetigt ein Argument (minimal|standard|power)" >&2
                    exit 2
                fi
                case "$2" in
                    minimal|standard|power) INSTALL_PROFILE="$2" ;;
                    *) echo "Ungueltiges Profil: $2 (minimal|standard|power)" >&2; exit 2 ;;
                esac
                shift 2
                ;;
            --ui)
                if [[ -z "${2:-}" ]]; then
                    echo "Fehler: --ui benoetigt ein Argument (mainsail|fluidd|none)" >&2
                    exit 2
                fi
                case "$2" in
                    mainsail|fluidd|none) HEADLESS_UI="$2" ;;
                    *) echo "Ungueltige UI: $2 (mainsail|fluidd|none)" >&2; exit 2 ;;
                esac
                shift 2
                ;;
            --yes|-y)   HEADLESS_CONFIRMED=1; shift ;;
            --dry-run)  HEADLESS_DRY_RUN=1; shift ;;
            --version)  echo "KATANAOS $KATANA_VERSION ($BUILD)"; exit 0 ;;
            --help|-h)  show_help; exit 0 ;;
            *)
                echo "Unbekannte Option: $1" >&2
                echo "Hilfe: ./katanaos.sh --help" >&2
                exit 2
                ;;
        esac
    done
}


# ==============================================================================
# 3. LOADER ARCHITEKTUR
# ==============================================================================

# Lädt Core-Module sicher (die UI Renderer sollten später keine Business-Logik mehr enthalten!)
require_module "$CORE_DIR/logging.sh"
require_module "$CORE_DIR/interaction.sh"
require_module "$CORE_DIR/ui_renderer.sh"
require_module "$CORE_DIR/env_check.sh"
require_module "$CORE_DIR/engine_manager.sh"

# Dispatcher & Service Module (Logik aus ui_renderer extrahiert)
require_module "$CORE_DIR/dispatchers.sh"
require_module "$CORE_DIR/headless.sh"
require_module "$CORE_DIR/service_manager.sh"

# Optionale Module (werden nur geladen, wenn sie existieren)
for opt_module in \
    "$MODULES_DIR/diagnostics/dr_katana.sh" \
    "$MODULES_DIR/diagnostics/medic.sh" \
    "$MODULES_DIR/hardware/menu.sh" \
    "$MODULES_DIR/hardware/can_manager.sh" \
    "$MODULES_DIR/hardware/flash_engine.sh" \
    "$MODULES_DIR/hardware/flash_registry.sh" \
    "$MODULES_DIR/hardware/katapult_manager.sh" \
    "$MODULES_DIR/security/hardening.sh" \
    "$MODULES_DIR/security/vault.sh" \
    "$MODULES_DIR/security/menu.sh" \
    "$MODULES_DIR/system/uninstaller.sh" \
    "$MODULES_DIR/system/backup_restore.sh" \
    "$MODULES_DIR/system/printer_config.sh" \
    "$MODULES_DIR/system/auto_restart.sh" \
    "$MODULES_DIR/system/mcu_builder.sh" \
    "$MODULES_DIR/system/moonraker_update_manager.sh" \
    "$MODULES_DIR/system/instance_manager.sh" \
    "$MODULES_DIR/extras/smart_probes.sh" \
    "$MODULES_DIR/extras/multi_material.sh" \
    "$MODULES_DIR/extras/katana_flow.sh" \
    "$MODULES_DIR/extras/tuning.sh" \
    "$MODULES_DIR/extras/toolchanger.sh" \
    "$MODULES_DIR/extras/timelapse.sh" \
    "$MODULES_DIR/engine/install_klipper.sh" \
    "$MODULES_DIR/ui/install_ui.sh" \
    "$MODULES_DIR/vision/install_crowsnest.sh"; do
    # An explicit `if` rather than `[[ -f ... ]] && source ...`: the && form
    # yields a non-zero status for every absent module, and with the ERR trap
    # armed during the load phase a single missing optional file would crash
    # the tool with a CRITICAL ERROR banner instead of degrading gracefully.
    if [[ -f "$opt_module" ]]; then
        source "$opt_module"
    fi
done

# --- HATCH ENGINE (Firmware/Board-Authority — conditional, graceful degradation) ---
if [[ -n "$HATCH_DIR" && -f "$HATCH_DIR/hatch.sh" ]]; then
    source "$HATCH_DIR/hatch.sh"
else
    # Fallback stub. The message names the resolution paths that are actually
    # implemented above — there is no `install.sh --hatch`, and KATANA does not
    # install HATCH: HATCH is the hardware/board authority and owns its own
    # provisioning (see CLAUDE.md, responsibility matrix).
    function init_hatch_menu() {
        log_error "HATCH ist nicht verfuegbar (Firmware-/Board-Funktionen sind deaktiviert)."
        log_info  "HATCH wird in dieser Reihenfolge gesucht:"
        log_info  "  1. $KATANA_ROOT/hatch/hatch.sh            (eingebettet)"
        log_info  "  2. \$KATANA_HATCH_REPO_DIR/hatch.sh        (externes Repo)"
        log_info  "  3. $HOME/.local/share/katana/hatch/hatch.sh  (managed)"
        log_info  "Vorgehen: HATCH klonen und den Pfad setzen, z.B."
        log_info  "  export KATANA_HATCH_REPO_DIR=/pfad/zu/HATCH && ./katanaos.sh"
        return 1
    }
fi


# ==============================================================================
# 4. ORCHESTRATOR / MAIN LOOP
# ==============================================================================

main() {
    # 1. CLI Parameter auswerten
    if [[ $# -gt 0 ]]; then
        handle_args "$@"
    fi

    # 1b. Unbeaufsichtigter Lauf: kein Menue, kein Prompt, sprechender Exit-Code.
    #     Der Env-Check laeuft in run_headless_install, damit --dry-run auch auf
    #     einer Nicht-Zielplattform den Plan ausgeben kann.
    #
    # Why the ERR trap is disarmed here, and what replaces it:
    #
    # A generic ERR trap and an exit-code contract cannot both own the status of
    # this call. error_trap prints a crash banner and exits with whatever code
    # fired it, while run_headless_install returns 0/1/2/3 as its documented
    # API. With the trap armed, a deliberate refusal ("--yes missing", exit 3)
    # reaches the operator as "Das Skript ist unerwartet abgestuerzt" — the tool
    # would lie about its own behaviour. So disarming is correct.
    #
    # What was wrong was disarming it without putting anything in its place:
    # the entire unattended install then ran with no error handling at all,
    # which is how a failed step could reach `log_success`. The replacement is
    # not another trap but checked returns, which catch strictly more:
    #
    #   - each step runs in a subshell under `set -euo pipefail`
    #     (headless_run_step), so an unchecked command failure inside a legacy
    #     install function aborts that step instead of falling through to its
    #     closing success message
    #   - each step's status is checked and the failing step is named on stderr
    #   - the run's status is the documented exit code, produced in one place
    #
    # A crash reporter firing on those same conditions would add a banner and
    # take away the exit code. It is not reinstated for that reason.
    if [[ "$HEADLESS_MODE" == "1" ]]; then
        trap - ERR
        local headless_rc=0
        run_headless_install "$INSTALL_PROFILE" "$HEADLESS_UI" \
            "$HEADLESS_CONFIRMED" "$HEADLESS_DRY_RUN" || headless_rc=$?
        exit "$headless_rc"
    fi

    # 2. System initialisieren (Root-Check & Env-Validation)
    log_info "KATANA $KATANA_VERSION wird initialisiert..."
    if ! check_environment; then
        log_error "Umgebungs-Check fehlgeschlagen. Abbruch."
        exit 1
    fi
    
    echo ""
    # C_PURPLE etc. stammen aus ui_renderer.sh
    echo -e "  ${C_PURPLE}KATANAOS $KATANA_VERSION${NC} | Profil: ${C_NEON}$INSTALL_PROFILE${NC}"
    echo ""
    sleep 1 # Kurzer Delay für Sichtbarkeit
    
    # 3. Main Loop (Bulletproof)
    # Der globale ERR-Trap schützt Ladephase & Preflight. Im interaktiven
    # Betrieb darf ein Unterbefehl mit 'return 1' (z.B. abgebrochene oder
    # fehlgeschlagene Installation) das Tool nicht beenden — solche Fehler
    # werden in den Modulen bereits via log_error gemeldet.
    trap - ERR
    while true; do
        draw_main_menu
        
        local choice
        # Ends the session on EOF (CTRL+D) and on any start without a human —
        # the same two conditions, handled in one place. katana_read_menu also
        # does the whitespace trim that used to be repeated here and in every
        # submenu, and forgotten in about half of them.
        if ! katana_read_menu choice "  >> COMMAND: " "HAUPTMENUE"; then
            log_info "Sitzung beendet (kein interaktives Terminal oder EOF)."
            break
        fi

        # Navigation
        case "$choice" in
            1) run_quick_start ;;       # Befindet sich idealerweise bald im Dispatcher-Modul
            2) run_forge_menu ;;
            3) run_extras_menu ;;
            4) run_update_menu ;;
            5) run_diagnose_menu ;;
            6) run_settings_menu ;;
            [hH]) run_extras_menu ;;
            [qQxX]) 
                # draw_exit_screen    # Optional falls implementiert
                log_info "KATANAOS regulär beendet."
                break 
                ;;
            *) 
                log_error "Ungültige Auswahl ('${choice}'). Bitte wähle eine Option aus dem Menü."
                sleep 1 
                ;;
        esac
    done
}

# --- KICKOFF ---
main "$@"

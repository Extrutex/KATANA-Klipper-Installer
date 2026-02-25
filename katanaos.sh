#!/usr/bin/env bash
################################################################################
#  ⚔️  KATANAOS - THE KLIPPER BLADE v2.6 (B2B Refactored)
# ------------------------------------------------------------------------------
#  PRO-GRADE KLIPPER INSTALLATION & MANAGEMENT SUITE
#  Modular Architecture | Native Flow | Bulletproof Error Handling
################################################################################

# --- EXECUTION MODE ---
# pipefail: Verhindert dass Pipe-Fehler verschluckt werden
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

# --- PROFILE HANDLER ---
# Standardprofil, überschreibbar via CLI
INSTALL_PROFILE="standard"
export INSTALL_PROFILE


# ==============================================================================
# 1. ERROR HANDLING & VALIDATION
# ==============================================================================

# Globaler Error Trap: Fängt alle unerwarteten Abstürze ab
error_trap() {
    local exit_code=$?
    local line_no=$1
    echo -e "\n\033[38;5;196m[CRITICAL ERROR] Das Skript ist unerwartet in Zeile ${line_no} mit Exit-Code ${exit_code} abgestürzt!\033[0m"
    echo "Bitte überprüfe die Log-Datei: $LOG_FILE"
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
    echo "  ./katanaos.sh              Startet das interaktive Menü"
    echo "  ./katanaos.sh --profile    Setzt das Installations-Profil:"
    echo "      minimal   - Nur Klipper + Moonraker"
    echo "      standard  - Core + Mainsail (Standard)"
    echo "      power     - Alles (CAN, Toolchanger, etc.)"
    echo "  ./katanaos.sh --version    Zeigt die Version an"
    echo "  ./katanaos.sh --help       Zeigt diese Hilfe an"
    echo ""
}

handle_args() {
    case "$1" in
        --profile)
            if [[ -z "${2:-}" ]]; then
                echo "Fehler: --profile benötigt ein Argument (minimal|standard|power)"
                exit 1
            fi
            case "$2" in
                minimal|standard|power) INSTALL_PROFILE="$2" ;;
                *) echo "Ungültiges Profil: $2"; exit 1 ;;
            esac
            echo "Profil erfolgreich gesetzt auf: $INSTALL_PROFILE"
            ;;
        --version)
            echo "KATANAOS $KATANA_VERSION ($BUILD)"
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
}


# ==============================================================================
# 3. LOADER ARCHITEKTUR
# ==============================================================================

# Lädt Core-Module sicher (die UI Renderer sollten später keine Business-Logik mehr enthalten!)
require_module "$CORE_DIR/logging.sh"
require_module "$CORE_DIR/ui_renderer.sh"
require_module "$CORE_DIR/env_check.sh"
require_module "$CORE_DIR/engine_manager.sh"

# Dispatcher & Service Module (Logik aus ui_renderer extrahiert)
require_module "$CORE_DIR/dispatchers.sh"
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
    [[ -f "$opt_module" ]] && source "$opt_module"
done


# ==============================================================================
# 4. ORCHESTRATOR / MAIN LOOP
# ==============================================================================

main() {
    # 1. CLI Parameter auswerten
    if [[ $# -gt 0 ]]; then
        handle_args "$@"
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
    while true; do
        draw_main_menu
        
        local choice
        if ! read -r -p "  >> COMMAND: " choice; then
            # Fängt CTRL+D (EOF) sauber ab
            echo ""
            log_info "Sitzung durch Benutzer (EOF) beendet."
            break
        fi
        
        # Trim whitespace from input
        choice="${choice#"${choice%%[![:space:]]*}"}"
        
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

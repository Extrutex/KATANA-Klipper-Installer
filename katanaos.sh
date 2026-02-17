#!/bin/bash
################################################################################
#  ⚔️  KATANAOS - THE KLIPPER BLADE v2.2
# ------------------------------------------------------------------------------
#  PRO-GRADE KLIPPER INSTALLATION & MANAGEMENT SUITE
#  Modular Architecture | Native Flow | Multi-Engine
################################################################################

# --- VERSION ---
VERSION="v2.2"
BUILD="2026-02-17"

# Fix terminal for proper display
export TERM=xterm-256color

# --- CONSTANTS & PATHS ---
KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$KATANA_ROOT/core"
MODULES_DIR="$KATANA_ROOT/modules"
CONFIGS_DIR="$KATANA_ROOT/configs"
LOG_FILE="$KATANA_ROOT/katana.log"

# --- PROFILE HANDLER ---
INSTALL_PROFILE="standard"
export INSTALL_PROFILE

function show_help() {
    echo "KATANAOS $VERSION - Usage:"
    echo ""
    echo "  ./katanaos.sh              Start interactive menu"
    echo "  ./katanaos.sh --profile    Set installation profile:"
    echo "      minimal   - Only Klipper + Moonraker"
    echo "      standard  - Core + Mainsail (default)"
    echo "      power     - Everything (CAN, Toolchanger, etc.)"
    echo "  ./katanaos.sh --version    Show version"
    echo "  ./katanaos.sh --help       Show this help"
    echo ""
}

function handle_args() {
    case "$1" in
        --profile)
            if [ -z "$2" ]; then
                echo "Error: --profile requires an argument (minimal|standard|power)"
                exit 1
            fi
            case "$2" in
                minimal|standard|power) INSTALL_PROFILE="$2" ;;
                *) echo "Invalid profile: $2"; exit 1 ;;
            esac
            echo "Profile set to: $INSTALL_PROFILE"
            ;;
        --version)
            echo "KATANAOS $VERSION ($BUILD)"
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
}

# --- CORE LOADER ---
source "$CORE_DIR/logging.sh"
source "$CORE_DIR/ui_renderer.sh"
source "$CORE_DIR/env_check.sh"
source "$CORE_DIR/engine_manager.sh"
source "$CORE_DIR/dispatchers.sh"
source "$CORE_DIR/service_manager.sh"
source "$MODULES_DIR/engine/install_klipper.sh"
# source "$MODULES_DIR/hardware/canbus.sh" # Deprecated/Merged into Forge
if [ -f "$MODULES_DIR/diagnostics/dr_katana.sh" ]; then
    source "$MODULES_DIR/diagnostics/dr_katana.sh"
    source "$MODULES_DIR/diagnostics/medic.sh"
fi
# Hardware Extensions
source "$MODULES_DIR/extras/install_happy_hare.sh"
source "$MODULES_DIR/hardware/smart_probe.sh"
source "$MODULES_DIR/hardware/menu.sh"
# Security & Vault
source "$MODULES_DIR/security/hardening.sh"
source "$MODULES_DIR/security/vault.sh"
source "$MODULES_DIR/security/menu.sh"

# System
source "$MODULES_DIR/system/uninstaller.sh"
source "$MODULES_DIR/system/backup_restore.sh"
source "$MODULES_DIR/system/printer_config.sh"
source "$MODULES_DIR/system/auto_restart.sh"
source "$MODULES_DIR/system/mcu_builder.sh"
source "$MODULES_DIR/system/moonraker_update_manager.sh"

# Extras
source "$MODULES_DIR/extras/toolchanger.sh"
source "$MODULES_DIR/extras/timelapse.sh"
source "$MODULES_DIR/extras/install_octoprint.sh"

# --- MAIN LOGIC ---
function main() {
    # Handle command line arguments
    if [ $# -gt 0 ]; then
        handle_args "$@"
    fi
    
    # 1. Initialize System
    log_info "KATANA $VERSION initializing..."
    check_environment  # Defined in core/env_check.sh
    
    echo ""
    echo -e "  ${C_PURPLE}KATANAOS $VERSION${NC} | Profile: ${C_NEON}$INSTALL_PROFILE${NC}"
    echo ""
    
    # 2. Main Loop
    while true; do
        draw_main_menu  # Defined in core/ui_renderer.sh
        read -p "  >> COMMAND: " choice
        
        case $choice in
            1) run_autopilot ;;
            2) run_installer_menu ;;
            3) run_ui_installer ;;
            4) run_vision_stack ;;
            5) run_forge ;;
            6) run_engine_manager ;;
            7) update_core_stack ;;
            8) run_dr_katana ;;
            9) run_katana_flow ;;
            10) run_hardware_menu ;;
            11) run_security_menu ;;
            12) run_backup_restore ;;
            13) run_uninstaller ;;
            14) run_printer_config_wizard ;;
            15) run_service_manager_menu ;;
            [hH]) run_hardware_menu ;;
            [qQxX]) 
                draw_exit_screen
                exit 0 
                ;;
            *) 
                log_error "Invalid Selection." 
                sleep 1 
                ;;
        esac
    done
}

# Start
main

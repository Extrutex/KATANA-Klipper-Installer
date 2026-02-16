#!/bin/bash
################################################################################
#  ⚔️  KATANAOS - THE KLIPPER BLADE v2.2
# ------------------------------------------------------------------------------
#  PRO-GRADE KLIPPER INSTALLATION & MANAGEMENT SUITE
#  Modular Architecture | Native Flow | Multi-Engine
################################################################################

# Fix terminal for proper display
export TERM=xterm-256color

# --- CONSTANTS & PATHS ---
KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$KATANA_ROOT/core"
MODULES_DIR="$KATANA_ROOT/modules"
CONFIGS_DIR="$KATANA_ROOT/configs"
LOG_FILE="$KATANA_ROOT/katana.log"

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
    # 1. Initialize System
    # clear -> Moved to ui_renderer for cleaner flicker control
    log_info "KATANA v2.2 initializing..."
    check_environment  # Defined in core/env_check.sh
    
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

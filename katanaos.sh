#!/bin/bash
################################################################################
#  ⚔️  KATANAOS - THE KLIPPER BLADE v2.0
# ------------------------------------------------------------------------------
#  PRO-GRADE KLIPPER INSTALLATION & MANAGEMENT SUITE
#  Modular Architecture | Native Flow | Multi-Engine
################################################################################

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
# source "$MODULES_DIR/hardware/canbus.sh" # Deprecated/Merged into Forge
if [ -f "$MODULES_DIR/diagnostics/dr_katana.sh" ]; then
    source "$MODULES_DIR/diagnostics/dr_katana.sh"
fi
# Hardware Extensions
source "$MODULES_DIR/extras/install_happy_hare.sh"
source "$MODULES_DIR/hardware/smart_probe.sh"
source "$MODULES_DIR/hardware/menu.sh"

# --- MAIN LOGIC ---
function main() {
    # 1. Initialize System
    # clear -> Moved to ui_renderer for cleaner flicker control
    log_info "KATANA v2.0 initializing..."
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
            7) run_dr_katana ;;
            8) run_katana_flow ;;
            9) run_security_menu ;;
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

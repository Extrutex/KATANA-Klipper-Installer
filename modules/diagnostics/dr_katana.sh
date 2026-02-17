#!/bin/bash
# --- DR. KATANA: DIAGNOSTICS & REPAIR ---

# Ensure Environment
if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$(dirname "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")")"
    MODULES_DIR="$KATANA_ROOT/modules"
fi

# Source Healer Module if available
if [ -f "$MODULES_DIR/diagnostics/healer.sh" ]; then
    source "$MODULES_DIR/diagnostics/healer.sh"
fi

function run_dr_katana() {
    while true; do
        draw_header "DR. KATANA - DIAGNOSTICS"
        echo "  [1] SERVICE CONTROL (Start/Stop)"
        echo "  [2] LOG VIEWER (Klippy.log)"
        echo "  [3] SYSTEM REPAIR (Permissions)"
        echo "  [4] DEEP DIAGNOSTICS (Create Zip)"
        echo "  [5] AUTO-HEALER (One-Click Fix)"
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " cmd
        
        case $cmd in
            1) service_control_menu ;;
            2) view_logs ;;     # Placeholder
            3) repair_system ;;
            4) run_system_diagnostics ;; # Defined in medic.sh
            5) 
                if type run_healer &>/dev/null; then
                    run_healer
                else
                    log_error "Healer module not loaded."
                fi
                ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function service_control_menu() {
    while true; do
        draw_header "SERVICE MANAGER"
        
        # Display Current Status
        local s_klipper=$(systemctl is-active klipper 2>/dev/null || echo "inactive")
        local s_moonraker=$(systemctl is-active moonraker 2>/dev/null || echo "inactive")
        local s_crowsnest=$(systemctl is-active crowsnest 2>/dev/null || echo "inactive")
        
        echo -e "  Klipper:   $s_klipper"
        echo -e "  Moonraker: $s_moonraker"
        echo -e "  Crowsnest: $s_crowsnest"
        echo ""
        echo "  [1] Start Klipper"
        echo "  [2] Stop Klipper"
        echo "  [3] Restart Klipper"
        echo ""
        echo "  [4] Start Moonraker"
        echo "  [5] Stop Moonraker"
        echo "  [6] Restart Moonraker"
        echo ""
        echo "  [B] Back"
        
        read -p "  >> " sc
        
        case $sc in
            1) exec_silent "Starting Klipper" "sudo systemctl start klipper" ;;
            2) exec_silent "Stopping Klipper" "sudo systemctl stop klipper" ;;
            3) exec_silent "Restarting Klipper" "sudo systemctl restart klipper" ;;
            
            4) exec_silent "Starting Moonraker" "sudo systemctl start moonraker" ;;
            5) exec_silent "Stopping Moonraker" "sudo systemctl stop moonraker" ;;
            6) exec_silent "Restarting Moonraker" "sudo systemctl restart moonraker" ;;
            
            [bB]) return ;;
        esac
    done
}

function view_logs() {
    if [ -f "$KATANA_ROOT/scripts/log_analyzer.sh" ]; then
        source "$KATANA_ROOT/scripts/log_analyzer.sh"
    else
        echo "  [!] Analyzer script missing."
    fi
    read -p "  Press Enter..."
}

function repair_system() {
    draw_header "SYSTEM REPAIR & UPDATE"
    echo "  1) Fix Permissions (Standard)"
    echo "  2) System Update (APT)"
    echo "  3) Fix Dependencies (Libraries)"
    echo "  B) Back"
    read -p "  >> " ch
    
    case $ch in
        1)
            if declare -f heal_permissions > /dev/null; then
                heal_permissions
            else
                log_info "Fixing Permissions (Manual Fallback)..."
                sudo chown -R $USER:$USER $HOME/printer_data $HOME/klipper $HOME/moonraker 2>/dev/null
                log_success "Permissions fixed."
            fi
            ;;
        2)
            log_info "Updating System..."
            if sudo -n true 2>/dev/null; then
                sudo apt-get update && sudo apt-get upgrade -y
            else
                echo "  [!] Sudo required."
                sudo apt-get update && sudo apt-get upgrade -y
            fi
            log_success "System Updated."
            ;;
        3)
            if declare -f heal_dependencies > /dev/null; then
                heal_dependencies
            else
                log_warn "Healer module not loaded. Cannot check dependencies."
            fi
            ;;
        [bB]) return ;;
    esac
    read -p "  Press Enter..."
}

#!/bin/bash
# --- KATANA DISPATCHERS ---

# 1. AUTO-PILOT
function run_autopilot() {
    draw_header "AUTO-PILOT (GOD MODE)"
    echo "  This will install everything:"
    echo "  - Core: Klipper & Moonraker"
    echo "  - UI: Mainsail"
    echo "  - Extras: KATANA-FLOW"
    echo ""
    read -p "  Start Auto-Pilot? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    # Core
    if [ -f "$MODULES_DIR/engine/install_klipper.sh" ]; then
        source "$MODULES_DIR/engine/install_klipper.sh"
        do_install_klipper "Standard"
        do_install_moonraker
    fi
    
    # UI
    if [ -f "$MODULES_DIR/ui/install_ui.sh" ]; then
        source "$MODULES_DIR/ui/install_ui.sh"
        do_install_mainsail
    fi
    
    # Extras
    if [ -f "$MODULES_DIR/extras/install_katana_flow.sh" ]; then
        source "$MODULES_DIR/extras/install_katana_flow.sh"
        install_katana_flow
    fi
    
    log_success "AUTO-PILOT COMPLETE."
    read -p "  Press Enter..."
}

# 2. CORE INSTALLER
function run_installer_menu() {
    if [ -f "$MODULES_DIR/engine/install_klipper.sh" ]; then
        source "$MODULES_DIR/engine/install_klipper.sh"
        install_core_stack
    else
        log_error "Module missing: engine/install_klipper.sh"
    fi
}

# 3. UI INSTALLER
function run_ui_installer() {
    if [ -f "$MODULES_DIR/ui/install_ui.sh" ]; then
        source "$MODULES_DIR/ui/install_ui.sh"
        install_ui_stack
    else
        log_error "Module missing: ui/install_ui.sh"
    fi
}

# 4. EXTRAS (Renamed from KATANA-FLOW only)
function run_katana_flow_installer() {
    if [ -f "$MODULES_DIR/extras/install_katana_flow.sh" ]; then
        source "$MODULES_DIR/extras/install_katana_flow.sh"
        # We now call the menu, not just the single function
        do_extras_menu
    else
        log_error "Module missing: extras/install_katana_flow.sh"
    fi
}

# 5. THE FORGE
function run_forge() {
    if [ -f "$MODULES_DIR/hardware/flash_registry.sh" ]; then
        source "$MODULES_DIR/hardware/flash_registry.sh"
        run_flash_menu
    else
        log_error "Module missing: hardware/flash_registry.sh"
    fi
}

# 8. MAINTENANCE (System Prep)
function run_system_prep() {
    draw_header "SYSTEM MAINTENANCE"
    echo "  This will update your system packages (apt-get)."
    echo ""
    read -p "  Proceed? [Y/n] " yn
    if [[ "$yn" =~ ^[nN] ]]; then return; fi
    
    log_info "Updating System..."
    if sudo -n true 2>/dev/null; then
        sudo apt-get update && sudo apt-get upgrade -y
        log_success "System Updated."
    else
        echo "  [!] Sudo required for system update."
        sudo apt-get update && sudo apt-get upgrade -y
    fi
    read -p "  Press Enter..."
}

# 9. SECURITY & BACKUP
function run_security_menu() {
    draw_header "SECURITY & BACKUP"
    echo "  1) System Hardening (UFW)"
    echo "  2) Backup Manager"
    echo "  B) Back"
    read -p "  >> " ch
    
    case $ch in
        1)
            if [ -f "$MODULES_DIR/security/hardening.sh" ]; then
                source "$MODULES_DIR/security/hardening.sh"
                install_security_stack
            fi
            ;;
        2)
            if [ -f "$CORE_DIR/backup_manager.sh" ]; then
                source "$CORE_DIR/backup_manager.sh"
                run_backup_menu
            fi
            ;;
        [bB]) return ;;
    esac
}

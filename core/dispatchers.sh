#!/bin/bash
# --- KATANA DISPATCHERS ---

# 1. AUTO-PILOT
function run_autopilot() {
    draw_header "AUTO-PILOT (GOD MODE)"
    echo "  Profile: $INSTALL_PROFILE"
    echo ""
    
    case "$INSTALL_PROFILE" in
        minimal)
            echo "  Installing MINIMAL profile:"
            echo "  - Core: Klipper & Moonraker only"
            ;;
        standard)
            echo "  Installing STANDARD profile:"
            echo "  - Core: Klipper & Moonraker"
            echo "  - UI: Mainsail"
            ;;
        power)
            echo "  Installing POWER profile:"
            echo "  - Core: Klipper & Moonraker"
            echo "  - UI: Mainsail + Crowsnest"
            echo "  - Extras: KATANA-FLOW, Toolchanger"
            ;;
    esac
    
    echo ""
    read -p "  Start? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    # Core - always installed
    if [ -f "$MODULES_DIR/engine/install_klipper.sh" ]; then
        source "$MODULES_DIR/engine/install_klipper.sh"
        do_install_klipper "Standard"
        do_install_moonraker
    fi
    
    # UI - standard & power
    if [[ "$INSTALL_PROFILE" == "standard" || "$INSTALL_PROFILE" == "power" ]]; then
        if [ -f "$MODULES_DIR/ui/install_ui.sh" ]; then
            source "$MODULES_DIR/ui/install_ui.sh"
            do_install_mainsail
        fi
    fi
    
    # Vision Stack - power only
    if [[ "$INSTALL_PROFILE" == "power" ]]; then
        if [ -f "$MODULES_DIR/vision/install_crowsnest.sh" ]; then
            source "$MODULES_DIR/vision/install_crowsnest.sh"
            install_vision_stack
        fi
    fi
    
    # Extras - power only
    if [[ "$INSTALL_PROFILE" == "power" ]]; then
        if [ -f "$MODULES_DIR/extras/katana_flow.sh" ]; then
            source "$MODULES_DIR/extras/katana_flow.sh"
            install_katana_flow
        fi
    fi
    
    log_success "AUTO-PILOT COMPLETE (Profile: $INSTALL_PROFILE)."
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

# 4. HMI & VISION (Renamed from KATANA-FLOW)
function run_vision_stack() {
    if [ -f "$MODULES_DIR/vision/install_crowsnest.sh" ]; then
        source "$MODULES_DIR/vision/install_crowsnest.sh"
        install_vision_stack
    else
        log_error "Module missing: vision/install_crowsnest.sh"
    fi
}

# 5. THE FORGE
function run_forge() {
    if [ -f "$MODULES_DIR/hardware/flash_registry.sh" ]; then
        source "$MODULES_DIR/hardware/flash_registry.sh"
        source "$MODULES_DIR/hardware/flash_engine.sh"
        run_flash_menu
    else
        log_error "Module missing: hardware/flash_registry.sh"
    fi
}

# 8. KATANA FLOW (Smart Purge)
function run_katana_flow() {
    if [ -f "$MODULES_DIR/extras/katana_flow.sh" ]; then
        source "$MODULES_DIR/extras/katana_flow.sh"
        install_katana_flow
    else
         log_error "Module missing: extras/katana_flow.sh"
    fi
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

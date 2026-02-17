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
    echo ""
    post_install_verify
    read -p "  Press Enter..."
}

# POST-INSTALL VERIFICATION
function post_install_verify() {
    draw_header "INSTALLATION SUMMARY"
    echo ""
    
    # Klipper
    if [ -d "$HOME/klipper" ]; then
        echo -e "  ${C_GREEN}✓${NC} Klipper          INSTALLED  ($HOME/klipper)"
    else
        echo -e "  ${C_RED}✗${NC} Klipper          NOT FOUND"
    fi
    
    # Klippy Env
    if [ -d "$HOME/klippy-env" ]; then
        echo -e "  ${C_GREEN}✓${NC} Klippy Env       INSTALLED"
    else
        echo -e "  ${C_RED}✗${NC} Klippy Env       NOT FOUND"
    fi
    
    # Moonraker
    if [ -d "$HOME/moonraker" ]; then
        echo -e "  ${C_GREEN}✓${NC} Moonraker        INSTALLED  ($HOME/moonraker)"
    else
        echo -e "  ${C_RED}✗${NC} Moonraker        NOT FOUND"
    fi
    
    # Moonraker Env
    if [ -d "$HOME/moonraker-env" ]; then
        echo -e "  ${C_GREEN}✓${NC} Moonraker Env    INSTALLED"
    else
        echo -e "  ${C_RED}✗${NC} Moonraker Env    NOT FOUND"
    fi
    
    # Web UI
    if [ -d "$HOME/mainsail" ]; then
        echo -e "  ${C_GREEN}✓${NC} Mainsail         INSTALLED"
    elif [ -d "$HOME/fluidd" ]; then
        echo -e "  ${C_GREEN}✓${NC} Fluidd           INSTALLED"
    else
        echo -e "  ${C_YELLOW}○${NC} Web UI           NOT INSTALLED"
    fi
    
    # Printer Data
    if [ -d "$HOME/printer_data" ]; then
        echo -e "  ${C_GREEN}✓${NC} Printer Data     READY  ($HOME/printer_data)"
    else
        echo -e "  ${C_RED}✗${NC} Printer Data     MISSING"
    fi
    
    echo ""
    echo "  ─── Services ───"
    echo ""
    
    # Service Status
    if systemctl is-active --quiet klipper 2>/dev/null; then
        echo -e "  ${C_GREEN}●${NC} klipper.service  RUNNING"
    elif systemctl is-enabled --quiet klipper 2>/dev/null; then
        echo -e "  ${C_YELLOW}●${NC} klipper.service  INSTALLED (not running - needs printer.cfg)"
    else
        echo -e "  ${C_RED}○${NC} klipper.service  NOT FOUND"
    fi
    
    if systemctl is-active --quiet moonraker 2>/dev/null; then
        echo -e "  ${C_GREEN}●${NC} moonraker        RUNNING"
    elif systemctl is-enabled --quiet moonraker 2>/dev/null; then
        echo -e "  ${C_YELLOW}●${NC} moonraker        INSTALLED (not running)"
    else
        echo -e "  ${C_RED}○${NC} moonraker        NOT FOUND"
    fi
    
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "  ${C_GREEN}●${NC} nginx            RUNNING"
    else
        echo -e "  ${C_GREY}○${NC} nginx            NOT RUNNING"
    fi
    
    echo ""
    echo "  ─── Next Steps ───"
    echo ""
    echo "  ${C_NEON}1.${NC} Go to ${C_GREEN}[2] FORGE${NC} → Build & Flash firmware for your MCU"
    echo "  ${C_NEON}2.${NC} Create/edit printer.cfg with your MCU serial"
    echo "  ${C_NEON}3.${NC} Klipper will go ONLINE once MCU is connected"
    echo ""
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
    if [ -f "$MODULES_DIR/hardware/flash_engine.sh" ]; then
        source "$MODULES_DIR/hardware/flash_engine.sh"
        run_hal_flasher
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
            if [ -f "$MODULES_DIR/system/backup_restore.sh" ]; then
                source "$MODULES_DIR/system/backup_restore.sh"
                run_backup_menu
            else
                log_error "Module missing: system/backup_restore.sh"
            fi
            ;;
        [bB]) return ;;
    esac
}

# 11. SMART PROBES
function run_smart_probes() {
    if [ -f "$MODULES_DIR/extras/smart_probes.sh" ]; then
        source "$MODULES_DIR/extras/smart_probes.sh"
        run_smartprobe_menu
    else
        log_error "Module missing: extras/smart_probes.sh"
    fi
}

# 12. MULTI-MATERIAL
function run_multi_material() {
    if [ -f "$MODULES_DIR/extras/multi_material.sh" ]; then
        source "$MODULES_DIR/extras/multi_material.sh"
        run_multimaterial_menu
    else
        log_error "Module missing: extras/multi_material.sh"
    fi
}

# 13. TUNING & SYSTEM
function run_tuning_tools() {
    if [ -f "$MODULES_DIR/extras/tuning.sh" ]; then
        source "$MODULES_DIR/extras/tuning.sh"
        run_tuning_menu
    else
        log_error "Module missing: extras/tuning.sh"
    fi
}
# 10. INSTANCE MANAGER
function run_instance_manager_dispatcher() {
    if [ -f "$MODULES_DIR/system/instance_manager.sh" ]; then
        source "$MODULES_DIR/system/instance_manager.sh"
        run_instance_manager
    else
        log_error "Module missing: system/instance_manager.sh"
    fi
}

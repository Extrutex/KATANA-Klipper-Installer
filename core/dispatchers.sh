#!/bin/bash
# --- KATANA DISPATCHERS ---

# 1. AUTO-PILOT
function run_autopilot() {
    draw_header "FULL INSTALLATION"
    echo ""
    echo "  This will install everything needed to run Klipper:"
    echo ""
    echo "  ${C_GREEN}✓${NC} Klipper        3D Printer Firmware"
    echo "  ${C_GREEN}✓${NC} Moonraker      API Server"
    echo "  ${C_GREEN}✓${NC} Web UI         Browser Interface"
    echo "  ${C_GREEN}✓${NC} Nginx          Web Server"
    echo "  ${C_GREEN}✓${NC} printer_data   Config & Logs Directory"
    echo ""
    
    # UI Selection
    echo "  ─── Web UI ───"
    echo ""
    echo "  ${C_NEON}[1]${NC}  Mainsail   (Recommended)"
    echo "  ${C_NEON}[2]${NC}  Fluidd"
    echo ""
    
    local ui_choice
    read -r -p "  >> Select UI [1/2]: " ui_choice
    
    case "$ui_choice" in
        1|"") ui_choice="mainsail" ;;
        2) ui_choice="fluidd" ;;
        *) ui_choice="mainsail" ;;
    esac
    
    echo ""
    echo "  ─────────────────────────────────"
    echo "  Installing: Klipper + Moonraker + ${ui_choice^}"
    echo "  ─────────────────────────────────"
    echo ""
    read -r -p "  Start Installation? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    echo ""
    
    # STEP 1: KLIPPER
    log_info "═══ STEP 1/3: KLIPPER ═══"
    if declare -f do_install_klipper > /dev/null; then
        do_install_klipper "Standard"
    else
        log_error "Klipper install function not found!"
        return 1
    fi
    
    # STEP 2: MOONRAKER
    echo ""
    log_info "═══ STEP 2/3: MOONRAKER ═══"
    if declare -f do_install_moonraker > /dev/null; then
        do_install_moonraker
    else
        log_error "Moonraker install function not found!"
        return 1
    fi
    
    # STEP 3: WEB UI
    echo ""
    log_info "═══ STEP 3/3: ${ui_choice^^} ═══"
    if [ "$ui_choice" = "fluidd" ]; then
        if declare -f do_install_fluidd > /dev/null; then
            do_install_fluidd
        else
            log_error "Fluidd install function not found!"
        fi
    else
        if declare -f do_install_mainsail > /dev/null; then
            do_install_mainsail
        else
            log_error "Mainsail install function not found!"
        fi
    fi
    
    echo ""
    log_success "═══ INSTALLATION COMPLETE ═══"
    echo ""
    post_install_verify
    read -r -p "  Press Enter..."
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

# 9. SECURITY & BACKUP → Handled by security/menu.sh (run_security_menu)

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
# 14. UPDATE DISPATCHER
function dispatch_update_menu() {
    while true; do
        draw_header "UPDATE MANAGER"
        echo "  ${C_GREEN}[1]${NC}  Update All              Klipper + Moonraker + all Extras"
        echo "  ${C_NEON}[2]${NC}  Klipper Only           Firmware"
        echo "  ${C_NEON}[3]${NC}  Moonraker Only         API Server"
        echo "  ${C_NEON}[4]${NC}  UI Only                Mainsail / Fluidd"
        echo "  ${C_NEON}[5]${NC}  Extras Only            All installed extensions"
        echo "  ${C_NEON}[6]${NC}  Check Only             Just check, don't install"
        echo ""
        echo "  [B] Back"
        echo ""
        
        local choice
        if ! read -r -p "  >> COMMAND: " choice; then return; fi
        choice="${choice#"${choice%%[![:space:]]*}"}"

        case "$choice" in
            1) 
               update_klipper_only
               update_moonraker_only
               update_extras_only
               ;;
            2) update_klipper_only ;;
            3) update_moonraker_only ;;
            4) update_ui_only ;;
            5) update_extras_only ;;
            6) check_updates_only ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ; sleep 1 ;;
        esac
    done
}

function update_klipper_only() {
    draw_header "UPDATE - KLIPPER"
    if [[ ! -d "$HOME/klipper" ]]; then
        log_error "Klipper directory not found"
        sleep 2
        return 1
    fi
    cd "$HOME/klipper" || return 1
    
    log_info "Pulling latest Klipper changes..."
    if ! git pull; then
        log_error "Git pull failed. Please check your config."
        read -r -p "  Drücke Enter..."
        return 1
    fi
    
    make clean
    make olddefconfig
    log_info "Building Klipper Firmware..."
    make -j"$(nproc)"
    
    log_info "Attempting to flash (assuming USB/default make flash)..."
    sudo make flash || log_warn "Automated flash failed or not applicable."
    
    read -r -p "  Drücke Enter..."
}

function update_moonraker_only() {
    draw_header "UPDATE - MOONRAKER"
    if [[ ! -d "$HOME/moonraker" ]]; then
        log_error "Moonraker directory not found"
        sleep 2
        return 1
    fi
    cd "$HOME/moonraker" || return 1
    
    log_info "Pulling latest Moonraker changes..."
    if ! git pull; then
        log_error "Git pull failed."
        read -r -p "  Drücke Enter..."
        return 1
    fi
    
    ./scripts/install.sh
    sudo systemctl restart moonraker
    log_success "Moonraker updated and restarted."
    read -r -p "  Drücke Enter..."
}

function update_ui_only() {
    draw_header "UPDATE - WEB UI"
    echo "  Select UI:"
    echo "  [1] Mainsail"
    echo "  [2] Fluidd"
    local ch
    if ! read -r -p "  >> " ch; then return; fi
    case "$ch" in
        1) cd "$HOME/mainsail" && git pull ;;
        2) cd "$HOME/fluidd" && git pull ;;
        *) return ;;
    esac
    log_success "UI Updated."
    read -r -p "  Drücke Enter..."
}

function update_extras_only() {
    draw_header "UPDATE - EXTRAS"
    log_info "Checking installed extras for updates..."

    local dirs=("$HOME/crowsnest" "$HOME/KlipperScreen" "$HOME/happy_hare" "$HOME/Cartographer" "$HOME/beacon" "$HOME/Eddy")
    for d in "${dirs[@]}"; do
        if [[ -d "$d/.git" ]]; then
            local name
            name=$(basename "$d")
            echo -ne "  [..] Updating $name..."
            if git -C "$d" pull --quiet 2>/dev/null; then
                echo -e "\r${C_GREEN}  [OK] $name updated${NC}    "
            else
                echo -e "\r${C_YELLOW}  [--] $name: no changes or error${NC}    "
            fi
        fi
    done

    log_success "Extras update check complete."
    read -r -p "  Press Enter..."
}

function check_updates_only() {
    draw_header "CHECK FOR UPDATES"
    log_info "Checking for available updates (no changes will be made)..."
    echo ""

    local dirs=("$HOME/klipper" "$HOME/moonraker" "$HOME/crowsnest" "$HOME/KlipperScreen")
    for d in "${dirs[@]}"; do
        if [[ -d "$d/.git" ]]; then
            local name
            name=$(basename "$d")
            git -C "$d" fetch --quiet 2>/dev/null
            local local_sha
            local_sha=$(git -C "$d" rev-parse HEAD 2>/dev/null)
            local remote_sha
            remote_sha=$(git -C "$d" rev-parse @{u} 2>/dev/null)
            if [[ "$local_sha" == "$remote_sha" ]]; then
                echo -e "  ${C_GREEN}●${NC} $name: up to date"
            else
                echo -e "  ${C_YELLOW}●${NC} $name: UPDATE AVAILABLE"
            fi
        fi
    done

    echo ""
    read -r -p "  Press Enter..."
}

# 15. DIAGNOSE DISPATCHER
function dispatch_diagnose_menu() {
    while true; do
        draw_header "DIAGNOSE"

        echo "  ${C_GREEN}[1]${NC}  Service Status        Check all services"
        echo "  ${C_NEON}[2]${NC}  Logs                  Klipper / Moonraker"
        echo "  ${C_NEON}[3]${NC}  Repair"
        echo "        |- Restart Klipper"
        echo "        |- Restart Moonraker"
        echo "        |- Configure Auto-Restart"
        echo "        '- Validate printer.cfg"
        echo "  ${C_NEON}[4]${NC}  Emergency"
        echo "        |- Full Reinstall"
        echo "        '- Complete Uninstall"
        echo ""
        echo "  [B] Back"
        echo ""
        
        local choice
        if ! read -r -p "  >> COMMAND: " choice; then return; fi
        choice="${choice#"${choice%%[![:space:]]*}"}"

        case "$choice" in
            1) check_all_services ;;
            2) show_logs_menu ;;
            3) run_repair_menu ;;
            4) run_emergency_menu ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ; sleep 1 ;;
        esac
    done
}

function check_all_services() {
    draw_header "SERVICE STATUS"
    systemctl status klipper --no-pager || true
    systemctl status moonraker --no-pager || true
    read -r -p "  Drücke Enter..."
}

function show_logs_menu() {
    while true; do
        draw_header "LOGS"
        echo "  [1] Klipper Logs"
        echo "  [2] Moonraker Logs"
        echo "  [3] Dmesg (USB)"
        echo "  [B] Back"
        
        local ch
        if ! read -r -p "  >> " ch; then return; fi
        case "$ch" in
            1) sudo journalctl -u klipper -n 50 ;;
            2) sudo journalctl -u moonraker -n 50 ;;
            3) dmesg | tail -n 30 ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ; sleep 1 ; continue ;;
        esac
        read -r -p "  Drücke Enter..."
    done
}

function run_repair_menu() {
    while true; do
        draw_header "REPAIR"
        echo "  [1] Restart Klipper"
        echo "  [2] Restart Moonraker"
        echo "  [3] Configure Auto-Restart"
        echo "  [B] Back"
        
        local ch
        if ! read -r -p "  >> " ch; then return; fi
        case "$ch" in
            1) sudo systemctl restart klipper ;;
            2) sudo systemctl restart moonraker ;;
            3) 
                if declare -f run_auto_restart > /dev/null; then
                    run_auto_restart
                else
                    log_error "Auto-Restart modul nicht geladen"
                    sleep 2
                fi
                ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ; sleep 1 ;;
        esac
    done
}

function run_emergency_menu() {
    while true; do
        draw_header "NOTFALL"
        echo "  [1] Komplette Neuinstallation"
        echo "  [2] Vollstaendige Deinstallation"
        echo "  [B] Back"
        
        local ch
        if ! read -r -p "  >> " ch; then return; fi
        case "$ch" in
            1) run_autopilot ;;
            2) 
                if declare -f run_uninstaller > /dev/null; then
                    run_uninstaller
                else
                    log_error "Uninstaller modul nicht geladen"
                    sleep 2
                fi
                ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ; sleep 1 ;;
        esac
    done
}

# 16. SETTINGS DISPATCHER
function dispatch_settings_menu() {
    while true; do
        draw_header "SETTINGS"

        echo "  ${C_GREEN}[1]${NC}  Profile                (minimal / standard / power)"
        echo "  ${C_NEON}[2]${NC}  Terminal               (Colors / Theme)"
        echo "  ${C_NEON}[3]${NC}  Instance Manager       (Add/Remove Instances)"
        echo "  ${C_NEON}[4]${NC}  CAN-Bus                (Network Config)"
        echo "  ${C_NEON}[5]${NC}  Engine Switch          (Klipper / Kalico / RatOS)"
        echo "  ${C_NEON}[6]${NC}  Uninstall              (Remove Everything)"
        echo "  ${C_NEON}[7]${NC}  Info                   (Version / Credits)"
        echo ""
        echo "  [B] Back"
        echo ""
        
        local choice
        if ! read -r -p "  >> COMMAND: " choice; then return; fi
        choice="${choice#"${choice%%[![:space:]]*}"}"

        case "$choice" in
            1) change_profile ;;
            2) change_theme ;;
            3) run_instance_manager_dispatcher ;;
            4) 
                if declare -f setup_can_network > /dev/null; then
                    setup_can_network
                else
                    log_error "CAN Network modul nicht geladen."
                    sleep 2
                fi
                ;;
            5) 
                if declare -f run_engine_manager > /dev/null; then
                    run_engine_manager
                else
                    log_error "Engine Manager modul nicht geladen"
                    sleep 2
                fi
                ;;
            6) 
                if declare -f run_uninstaller > /dev/null; then
                    run_uninstaller
                else
                    log_error "Uninstaller modul nicht geladen"
                    sleep 2
                fi
                ;;
            7) show_info ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ; sleep 1 ;;
        esac
    done
}

function change_profile() {
    draw_header "CHANGE PROFILE"
    echo "  Current: $INSTALL_PROFILE"
    echo "  [1] minimal   - Only Klipper + Moonraker"
    echo "  [2] standard  - Core + Mainsail (default)"
    echo "  [3] power     - Everything"
    local ch
    if ! read -r -p "  >> " ch; then return; fi
    case "$ch" in
        1) INSTALL_PROFILE="minimal" ;;
        2) INSTALL_PROFILE="standard" ;;
        3) INSTALL_PROFILE="power" ;;
        *) log_error "Abbruch." ; sleep 1 ; return ;;
    esac
    log_success "Profile Changed to $INSTALL_PROFILE"
    read -r -p "  Drücke Enter..."
}

function change_theme() {
    draw_header "THEME"
    echo "  Theme switching coming soon..."
    read -r -p "  Drücke Enter..."
}

function show_info() {
    draw_header "KATANAOS INFO"
    echo "  Building modern deployments."
    echo "  Profile: $INSTALL_PROFILE"
    read -r -p "  Drücke Enter..."
}

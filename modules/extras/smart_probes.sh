#!/bin/bash
# ==============================================================================
# KATANA MODULE: SMART PROBES
# Implementations for: Beacon, Cartographer, BTT Eddy
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$KATANA_ROOT/core/logger.sh"
    source "$KATANA_ROOT/modules/system/moonraker_update_manager.sh"
fi

# ============================================================
# 1. BEACON 3D
# ============================================================
function install_beacon() {
    draw_header "INSTALL BEACON 3D"
    echo "  Next-Gen Z-Probe. Real-time Z-offset & mesh."
    echo ""
    
    local install_dir="$HOME/beacon"
    
    if [ -d "$install_dir" ]; then
        log_warn "Beacon already exists at $install_dir"
        read -r -p "  Reinstall/Update? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$install_dir"
    fi
    
    log_info "Cloning BeaconKlipper..."
    git clone https://github.com/beacon3d/BeaconKlipper.git "$install_dir" || {
        log_error "Failed to clone Beacon repository."
        return 1
    }
    
    log_info "Running Beacon install script..."
    if [ -f "$install_dir/install.sh" ]; then
        bash "$install_dir/install.sh" || {
            log_error "Beacon install script failed."
            return 1
        }
    else
        log_error "install.sh not found in Beacon repo."
    fi
    
    # Register update manager
    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "Beacon" "git_repo" "$install_dir" "https://github.com/beacon3d/BeaconKlipper.git" "klipper"
    fi
    
    log_success "Beacon installed successfully."
    echo ""
    echo "  [!] ACTION REQUIRED: Add '[beacon]' to your printer.cfg"
    read -r -p "  Press Enter..."
}

function remove_beacon() {
    draw_header "REMOVE BEACON 3D"
    local install_dir="$HOME/beacon"
    
    if [ ! -d "$install_dir" ]; then
        log_warn "Beacon is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove Beacon completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Removing Beacon..."
    rm -rf "$install_dir"
    log_success "Beacon removed."
    echo "  [!] Remove '[beacon]' section from printer.cfg manually."
    read -r -p "  Press Enter..."
}

# ============================================================
# 2. CARTOGRAPHER
# ============================================================
function install_cartographer() {
    draw_header "INSTALL CARTOGRAPHER"
    echo "  High-speed eddy current scanning probe."
    echo ""
    
    local install_dir="$HOME/cartographer-klipper"
    
    if [ -d "$install_dir" ]; then
        log_warn "Cartographer already exists."
        read -r -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$install_dir"
    fi
    
    log_info "Cloning Cartographer..."
    git clone https://github.com/Cartographer3D/Cartographer-Klipper.git "$install_dir" || {
        log_error "Failed to clone Cartographer."
        return 1
    }
    
    log_info "Running install script..."
    if [ -f "$install_dir/install.sh" ]; then
        bash "$install_dir/install.sh" || {
            log_error "Cartographer install failed."
            return 1
        }
    else
        log_error "install.sh missing."
    fi
    
    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "Cartographer" "git_repo" "$install_dir" "https://github.com/Cartographer3D/Cartographer-Klipper.git" "klipper"
    fi
    
    log_success "Cartographer installed."
    echo "  [!] Remember to run the survey script if needed."
    read -r -p "  Press Enter..."
}

function remove_cartographer() {
    draw_header "REMOVE CARTOGRAPHER"
    local install_dir="$HOME/cartographer-klipper"
    
    if [ ! -d "$install_dir" ]; then
        log_warn "Cartographer is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove Cartographer completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Removing Cartographer..."
    rm -rf "$install_dir"
    log_success "Cartographer removed."
    echo "  [!] Remove Cartographer sections from printer.cfg manually."
    read -r -p "  Press Enter..."
}

# ============================================================
# 3. BTT EDDY
# ============================================================
function install_btt_eddy() {
    draw_header "INSTALL BTT EDDY"
    echo "  BigTreeTech's Eddy Current Probe."
    echo ""
    echo "  NOTE: BTT Eddy is supported in mainline Klipper."
    echo "  We install the official BTT Repo for examples/macros."
    echo ""
    
    read -r -p "  Install/Update BTT Eddy Resources? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    local repo_dir="$HOME/Eddy"
    local config_dir="$HOME/printer_data/config/btt_eddy"
    
    if [ -d "$repo_dir" ]; then
        log_info "Updating existing BTT Eddy repo..."
        git -C "$repo_dir" pull || log_warn "Git pull failed."
    else
        log_info "Cloning BTT Eddy..."
        git clone https://github.com/bigtreetech/Eddy.git "$repo_dir" || {
            log_error "Failed to clone BTT Eddy repo."
            return 1
        }
    fi
    
    log_info "Copying configuration templates..."
    mkdir -p "$config_dir"
    
    if [ -d "$repo_dir/Configs" ]; then
        cp -r "$repo_dir/Configs/"* "$config_dir/"
        log_success "Configs copied to $config_dir"
    elif [ -d "$repo_dir/klipper_config" ]; then
        cp -r "$repo_dir/klipper_config/"* "$config_dir/"
        log_success "Configs copied to $config_dir"
    else
        log_warn "Could not find config folder in repo."
    fi
    
    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "BTT_Eddy" "git_repo" "$repo_dir" "https://github.com/bigtreetech/Eddy.git" "klipper"
    fi
    
    echo ""
    echo "  [!] ACTION REQUIRED: Include the relevant .cfg in printer.cfg"
    read -r -p "  Press Enter..."
}

function remove_btt_eddy() {
    draw_header "REMOVE BTT EDDY"
    local repo_dir="$HOME/Eddy"
    local config_dir="$HOME/printer_data/config/btt_eddy"
    
    if [ ! -d "$repo_dir" ] && [ ! -d "$config_dir" ]; then
        log_warn "BTT Eddy is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove BTT Eddy completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Removing BTT Eddy..."
    rm -rf "$repo_dir" "$config_dir"
    log_success "BTT Eddy removed."
    echo "  [!] Remove BTT Eddy sections from printer.cfg manually."
    read -r -p "  Press Enter..."
}

# ============================================================
# 4. SMART PROBE MENU
# ============================================================
function run_smartprobe_menu() {
    while true; do
        draw_header "SMART PROBES"
        
        local beacon="NOT INSTALLED"
        if [ -d "$HOME/beacon" ]; then beacon="${C_GREEN}INSTALLED${NC}"; fi
        
        local carto="NOT INSTALLED"
        if [ -d "$HOME/cartographer-klipper" ]; then carto="${C_GREEN}INSTALLED${NC}"; fi
        
        local eddy="NOT INSTALLED"
        if [ -d "$HOME/Eddy" ]; then eddy="${C_GREEN}INSTALLED${NC}"; fi
        
        echo ""
        echo "  --- Install ---"
        echo "  ${C_NEON}[1]${NC}  Beacon 3D              [$beacon]"
        echo "  ${C_NEON}[2]${NC}  Cartographer           [$carto]"
        echo "  ${C_NEON}[3]${NC}  BTT Eddy               [$eddy]"
        echo ""
        echo "  --- Remove ---"
        echo "  ${C_RED}[4]${NC}  Remove Beacon"
        echo "  ${C_RED}[5]${NC}  Remove Cartographer"
        echo "  ${C_RED}[6]${NC}  Remove BTT Eddy"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_beacon ;;
            2) install_cartographer ;;
            3) install_btt_eddy ;;
            4) remove_beacon ;;
            5) remove_cartographer ;;
            6) remove_btt_eddy ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

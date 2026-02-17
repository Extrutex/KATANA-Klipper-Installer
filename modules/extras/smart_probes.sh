# ==============================================================================
# KATANA MODULE: SMART PROBES
# Implementations for: Beacon, Cartographer, BTT Eddy
# ==============================================================================

# Source core for logging if not already loaded
if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$HOME/KATANA_INSTALLER"
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
        read -p "  Reinstall/Update? [y/N]: " yn
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
    if declare -f register_beacon_updates > /dev/null; then
        register_beacon_updates
    else
        add_update_manager_entry "Beacon" "git_repo" "$install_dir" "https://github.com/beacon3d/BeaconKlipper.git" "klipper"
    fi
    
    log_success "Beacon installed successfully."
    echo ""
    echo "  [!] ACTION REQUIRED: Add '[beacon]' to your printer.cfg"
    echo "  [!] UUID detection is available in the 'Forge' menu."
    read -p "  Press Enter..."
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
        read -p "  Reinstall? [y/N]: " yn
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
        # Cartos install script handles dependencies
        bash "$install_dir/install.sh" || {
            log_error "Cartographer install failed."
            return 1
        }
    else
        log_error "install.sh missing."
    fi
    
    # Register update
    if declare -f register_cartographer_updates > /dev/null; then
         register_cartographer_updates
    else
         add_update_manager_entry "Cartographer" "git_repo" "$install_dir" "https://github.com/Cartographer3D/Cartographer-Klipper.git" "klipper"
    fi
    
    log_success "Cartographer installed."
    echo "  [!] Remember to run the survey script if needed."
    read -p "  Press Enter..."
}

# ============================================================
# 3. BTT EDDY
# ============================================================
function install_btt_eddy() {
    draw_header "INSTALL BTT EDDY"
    echo "  BigTreeTech's Eddy Current Probe."
    echo ""
    echo "  NOTE: BTT Eddy is supported in mainline Klipper since recent versions."
    echo "  We will setup the official BTT Repo for examples/macros."
    echo ""
    
    read -p "  Install/Update BTT Eddy Resources? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    local repo_dir="$HOME/Eddy"
    local config_dir="$HOME/printer_data/config/btt_eddy"
    
    # 1. Clone Repo
    if [ -d "$repo_dir" ]; then
        log_info "Updating existing BTT Eddy repo..."
        git -C "$repo_dir" pull || log_warn "Git pull failed. Proceeding with existing files."
    else
        log_info "Cloning BTT Eddy..."
        git clone https://github.com/bigtreetech/Eddy.git "$repo_dir" || {
            log_error "Failed to clone BTT Eddy repo."
            return 1
        }
    fi
    
    # 2. Copy Configs
    log_info "Copying configuration templates..."
    mkdir -p "$config_dir"
    
    if [ -d "$repo_dir/Configs" ]; then
        cp -r "$repo_dir/Configs/"* "$config_dir/"
        log_success "Configs copied to $config_dir"
    elif [ -d "$repo_dir/klipper_config" ]; then
        # Fallback for potential repo structure changes
        cp -r "$repo_dir/klipper_config/"* "$config_dir/"
        log_success "Configs copied to $config_dir"
    else
        log_warn "Could not find 'Configs' folder in repo. You may need to copy files manually."
    fi
    
    # 3. Register Updates
    if declare -f register_btt_eddy_updates > /dev/null; then
        register_btt_eddy_updates
    else
        # Fallback if helper missing
        if declare -f add_update_manager_entry > /dev/null; then
             add_update_manager_entry "BTT_Eddy" "git_repo" "$repo_dir" "https://github.com/bigtreetech/Eddy.git" "klipper"
        fi
    fi
    
    echo ""
    echo "  [!] ACTION REQUIRED: Include the relevant .cfg in printer.cfg"
    read -p "  Press Enter..."
}

# ============================================================
# 4. SMART PROBE MENU
# ============================================================
function run_smartprobe_menu() {
    while true; do
        draw_header "SMART PROBES"
        
        local beacon="NOT INSTALLED"
        if [ -d "$HOME/beacon" ]; then beacon="INSTALLED"; fi
        
        local carto="NOT INSTALLED"
        if [ -d "$HOME/cartographer-klipper" ]; then carto="INSTALLED"; fi
        
        local eddy="NOT INSTALLED"
         if [ -d "$HOME/Eddy" ]; then eddy="INSTALLED"; fi
        
        echo "  ${C_NEON}[1]${NC}  Beacon 3D              [$beacon]"
        echo "  ${C_NEON}[2]${NC}  Cartographer           [$carto]"
        echo "  ${C_NEON}[3]${NC}  BTT Eddy               [$eddy]"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_beacon ;;
            2) install_cartographer ;;
            3) install_btt_eddy ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

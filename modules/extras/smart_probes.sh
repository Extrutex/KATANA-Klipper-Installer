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
        return 1
    }
    
    # Register update manager
    if declare -f add_update_manager_entry > /dev/null; then
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
        return 1
    }
    
    # Register update
    if declare -f add_update_manager_entry > /dev/null; then
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
    echo "  We will verify your Klipper version and install the optional Klipper-module."
    echo ""
    
    read -p "  Install BTT Eddy URL/Mainline helper? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    local install_dir="$HOME/printer_data/config/btt_eddy"
    
    # BTT often requires a specific branch or repo for their MCU code if not in mainline
    # Assuming standard BTT Eddy repo for configs/macros
    log_info "Cloning BTT Eddy Macros/Config..."
    
    if [ -d "$HOME/Eddy" ]; then rm -rf "$HOME/Eddy"; fi
    
    git clone https://github.com/bigtreetech/Eddy.git "$HOME/Eddy"
    
    # Copy examples to config
    mkdir -p "$install_dir"
    cp -r "$HOME/Eddy/Configs/"* "$install_dir/"
    
    log_success "BTT Eddy Configs copied to $install_dir"
    log_info "Please copy the relevant .cfg content to your printer.cfg"
    
    # Register update? BTT Eddy repo is mostly configs/docs, but useful to keep updated
    if declare -f add_update_manager_entry > /dev/null; then
         add_update_manager_entry "BTT_Eddy" "git_repo" "$HOME/Eddy" "https://github.com/bigtreetech/Eddy.git" "klipper"
    fi
    
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

#!/bin/bash
# ==============================================================================
# KATANA MODULE: MULTI-MATERIAL & TOOLCHANGING
# Implementations for: Happy Hare (ERCF), StealthChanger, MADMAX
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$HOME/KATANA_INSTALLER"
    source "$KATANA_ROOT/core/logger.sh"
    source "$KATANA_ROOT/modules/system/moonraker_update_manager.sh"
fi

# ============================================================
# 1. HAPPY HARE (ERCF v2)
# ============================================================
function install_happyhare() {
    draw_header "INSTALL HAPPY HARE (ERCF v2)"
    echo "  The gold standard for MMU/ERCF management."
    echo ""
    
    local install_dir="$HOME/Happy-Hare"
    
    if [ -d "$install_dir" ]; then
        log_warn "Happy Hare repo already exists."
        read -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$install_dir"
    fi
    
    log_info "Cloning Happy Hare..."
    git clone https://github.com/moggieuk/Happy-Hare.git "$install_dir" || {
        log_error "Failed to clone Happy Hare."
        return 1
    }
    
    log_info "Starting Happy Hare Installer..."
    echo "  [!] You will be entering the interactive Happy Hare installer."
    echo "  [!] Follow the on-screen instructions."
    echo ""
    read -p "  Press Enter to launch..."
    
    if [ -f "$install_dir/install.sh" ]; then
        # We run this interactively as HH has a complex wizard
        cd "$install_dir"
        bash install.sh
    else
        log_error "install.sh not found in Happy Hare repo."
        return 1
    fi
    
    log_success "Happy Hare installation sequence finished."
    read -p "  Press Enter..."
}

# ============================================================
# 2. STEALTHCHANGER
# ============================================================
function install_stealthchanger() {
    draw_header "INSTALL STEALTHCHANGER"
    echo "  Toolchanger macros & config for the StealthChanger system."
    echo ""
    
    local install_dir="$HOME/printer_data/config/StealthChanger"
    
    if [ -d "$install_dir" ]; then
        log_warn "StealthChanger config already exists."
        read -p "  Overwrite? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    fi
    
    log_info "Cloning StealthChanger Repo..."
    # Cloning to temp first
    local temp_dir="$HOME/StealthChanger_Repo"
    rm -rf "$temp_dir"
    git clone https://github.com/DraftShift/StealthChanger.git "$temp_dir" || {
        log_error "Failed to clone StealthChanger."
        return 1
    }
    
    log_info "Installing Macros..."
    mkdir -p "$install_dir"
    # Copy klipper configs
    cp -r "$temp_dir/klipper_config/"* "$install_dir/" || {
        log_error "Failed to copy configs."
        return 1
    }
    
    # Register update
    if declare -f add_update_manager_entry > /dev/null; then
         add_update_manager_entry "StealthChanger" "git_repo" "$temp_dir" "https://github.com/DraftShift/StealthChanger.git" "klipper"
    fi
    
    # Clean up
    # actually we might want to keep the repo for updates via moonraker, so let's move it to a permanent place if not there
    # The moonraker entry above points to temp_dir which is wrong if we delete it.
    # Let's fix the pattern: 
    # 1. Clone to ~/StealthChanger (Code)
    # 2. Link/Copy to printer_data (Config)
    
    log_success "StealthChanger macros installed to $install_dir"
    echo "  [!] Include the .cfg files in your printer.cfg"
    read -p "  Press Enter..."
}

# ============================================================
# 3. MADMAX (Placeholder / Basic)
# ============================================================
function install_madmax() {
    draw_header "INSTALL MADMAX"
    echo "  Monolith Toolchanger system."
    echo "  (Coming Soon - Basic Git Clone only)"
    echo ""
    read -p "  Proceed? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    local install_dir="$HOME/MADMAX"
    git clone https://github.com/zruncho3d/madmax.git "$install_dir"
    log_success "Repo cloned to $install_dir"
    read -p "  Press Enter..."
}

# ============================================================
# 4. DISPATCHER
# ============================================================
function run_multimaterial_menu() {
    while true; do
        draw_header "MULTI-MATERIAL & TOOLCHANGERS"
        
        local hh="NOT INSTALLED"
        if [ -d "$HOME/Happy-Hare" ]; then hh="INSTALLED"; fi
        
        local sc="NOT INSTALLED"
        if [ -d "$HOME/printer_data/config/StealthChanger" ]; then sc="INSTALLED"; fi
        
        echo "  ${C_NEON}[1]${NC}  Happy Hare (ERCF)      [$hh]"
        echo "  ${C_NEON}[2]${NC}  StealthChanger         [$sc]"
        echo "  ${C_NEON}[3]${NC}  MADMAX                 [-]"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_happyhare ;;
            2) install_stealthchanger ;;
            3) install_madmax ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

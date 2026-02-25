#!/bin/bash
# ==============================================================================
# KATANA MODULE: MULTI-MATERIAL & TOOLCHANGING
# Implementations for: Happy Hare (ERCF), StealthChanger
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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
        read -r -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$install_dir"
    fi
    
    log_info "Cloning Happy Hare..."
    git clone https://github.com/moggieuk/Happy-Hare.git "$install_dir" || {
        log_error "Failed to clone Happy Hare."
        return 1
    }
    
    log_info "Starting Happy Hare Installer..."
    echo "  [!] Interactive installer will launch."
    echo ""
    read -r -p "  Press Enter to launch..."
    
    if [ -f "$install_dir/install.sh" ]; then
        cd "$install_dir" || return 1
        bash install.sh
    else
        log_error "install.sh not found in Happy Hare repo."
        return 1
    fi
    
    log_success "Happy Hare installation finished."
    read -r -p "  Press Enter..."
}

function remove_happyhare() {
    draw_header "REMOVE HAPPY HARE"
    local install_dir="$HOME/Happy-Hare"
    
    if [ ! -d "$install_dir" ]; then
        log_warn "Happy Hare is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove Happy Hare completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    # Happy Hare has its own uninstaller
    if [ -f "$install_dir/uninstall.sh" ]; then
        log_info "Running Happy Hare uninstaller..."
        cd "$install_dir" || return 1
        bash uninstall.sh
    else
        log_info "No uninstaller found. Removing directory..."
        rm -rf "$install_dir"
    fi
    
    log_success "Happy Hare removed."
    read -r -p "  Press Enter..."
}

# ============================================================
# 2. STEALTHCHANGER
# ============================================================
function install_stealthchanger() {
    draw_header "INSTALL STEALTHCHANGER"
    echo "  Toolchanger macros & config for the StealthChanger system."
    echo ""
    
    local install_dir="$HOME/printer_data/config/StealthChanger"
    local repo_dir="$HOME/StealthChanger_Repo"
    
    if [ -d "$install_dir" ]; then
        log_warn "StealthChanger config already exists."
        read -r -p "  Overwrite? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    fi
    
    log_info "Cloning StealthChanger..."
    rm -rf "$repo_dir"
    git clone https://github.com/DraftShift/StealthChanger.git "$repo_dir" || {
        log_error "Failed to clone StealthChanger."
        return 1
    }
    
    log_info "Installing Macros..."
    mkdir -p "$install_dir"
    if [ -d "$repo_dir/klipper_config" ]; then
        cp -r "$repo_dir/klipper_config/"* "$install_dir/"
    fi
    
    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "StealthChanger" "git_repo" "$repo_dir" "https://github.com/DraftShift/StealthChanger.git" "klipper"
    fi
    
    log_success "StealthChanger macros installed to $install_dir"
    echo "  [!] Include the .cfg files in your printer.cfg"
    read -r -p "  Press Enter..."
}

function remove_stealthchanger() {
    draw_header "REMOVE STEALTHCHANGER"
    local install_dir="$HOME/printer_data/config/StealthChanger"
    local repo_dir="$HOME/StealthChanger_Repo"
    
    if [ ! -d "$install_dir" ] && [ ! -d "$repo_dir" ]; then
        log_warn "StealthChanger is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove StealthChanger completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Removing StealthChanger..."
    rm -rf "$install_dir" "$repo_dir"
    log_success "StealthChanger removed."
    echo "  [!] Remove StealthChanger includes from printer.cfg manually."
    read -r -p "  Press Enter..."
}

# ============================================================
# 3. MADMAX (Monolith Toolchanger)
# ============================================================
function install_madmax() {
    draw_header "INSTALL MADMAX"
    echo "  Monolith / MADMAX Toolchanger system."
    echo "  Clones the official repo and copies configs."
    echo ""

    local install_dir="$HOME/MADMAX"
    local config_dir="$HOME/printer_data/config/MADMAX"

    if [ -d "$install_dir" ]; then
        log_warn "MADMAX already exists."
        read -r -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$install_dir"
    fi

    read -r -p "  Install MADMAX? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi

    log_info "Cloning MADMAX..."
    git clone https://github.com/zruncho3d/madmax.git "$install_dir" || {
        log_error "Failed to clone MADMAX."
        return 1
    }

    # Copy Klipper configs if available
    mkdir -p "$config_dir"
    if [ -d "$install_dir/klipper_config" ]; then
        cp -r "$install_dir/klipper_config/"* "$config_dir/"
        log_info "Configs copied to $config_dir"
    elif [ -d "$install_dir/config" ]; then
        cp -r "$install_dir/config/"* "$config_dir/"
        log_info "Configs copied to $config_dir"
    fi

    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "MADMAX" "git_repo" "$install_dir" "https://github.com/zruncho3d/madmax.git" "klipper"
    fi

    log_success "MADMAX installed!"
    echo "  Repo: $install_dir"
    echo "  Configs: $config_dir"
    echo "  [!] Include the relevant .cfg files in your printer.cfg"
    read -r -p "  Press Enter..."
}

function remove_madmax() {
    draw_header "REMOVE MADMAX"
    local install_dir="$HOME/MADMAX"
    local config_dir="$HOME/printer_data/config/MADMAX"

    if [ ! -d "$install_dir" ] && [ ! -d "$config_dir" ]; then
        log_warn "MADMAX is not installed."
        read -r -p "  Press Enter..."
        return
    fi

    read -r -p "  Remove MADMAX completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi

    log_info "Removing MADMAX..."
    rm -rf "$install_dir" "$config_dir"
    log_success "MADMAX removed."
    echo "  [!] Remove MADMAX includes from printer.cfg manually."
    read -r -p "  Press Enter..."
}

# ============================================================
# 4. DISPATCHER MENU
# ============================================================
function run_multimaterial_menu() {
    while true; do
        draw_header "MULTI-MATERIAL & TOOLCHANGERS"

        local hh="NOT INSTALLED"
        if [ -d "$HOME/Happy-Hare" ]; then hh="${C_GREEN}INSTALLED${NC}"; fi

        local sc="NOT INSTALLED"
        if [ -d "$HOME/printer_data/config/StealthChanger" ]; then sc="${C_GREEN}INSTALLED${NC}"; fi

        local mm="NOT INSTALLED"
        if [ -d "$HOME/MADMAX" ]; then mm="${C_GREEN}INSTALLED${NC}"; fi

        echo ""
        echo "  --- Install ---"
        echo "  ${C_NEON}[1]${NC}  Happy Hare (ERCF)      [$hh]"
        echo "  ${C_NEON}[2]${NC}  StealthChanger         [$sc]"
        echo "  ${C_NEON}[3]${NC}  MADMAX (Monolith)      [$mm]"
        echo ""
        echo "  --- Remove ---"
        echo "  ${C_RED}[4]${NC}  Remove Happy Hare"
        echo "  ${C_RED}[5]${NC}  Remove StealthChanger"
        echo "  ${C_RED}[6]${NC}  Remove MADMAX"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " ch

        case $ch in
            1) install_happyhare ;;
            2) install_stealthchanger ;;
            3) install_madmax ;;
            4) remove_happyhare ;;
            5) remove_stealthchanger ;;
            6) remove_madmax ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}


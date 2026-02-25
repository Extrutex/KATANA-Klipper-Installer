#!/bin/bash
# ==============================================================================
# KATANA MODULE: TUNING & SYSTEM TOOLS
# Implementations for: ShakeTune, Log2Ram
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$KATANA_ROOT/core/logger.sh"
    source "$KATANA_ROOT/modules/system/moonraker_update_manager.sh"
fi

# ============================================================
# 1. SHAKETUNE (Single Source of Truth)
# ============================================================
function install_shaketune() {
    draw_header "INSTALL K-SHAKETUNE"
    echo "  Vibration analysis & Input Shaper visualization."
    echo ""
    echo "  [!] REQUIRED: matplotlib, numpy, scipy"
    echo "  [!] This might take a while on a Pi Zero/3."
    echo ""
    
    local install_dir="$HOME/klippain_shaketune"
    
    if [ -d "$install_dir" ]; then
        log_warn "ShakeTune already exists."
        read -r -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$install_dir"
    fi
    
    log_info "Cloning Klippain ShakeTune..."
    git clone https://github.com/Frix-x/klippain-shaketune.git "$install_dir" || {
        log_error "Clone failed."
        return 1
    }
    
    log_info "Running Install Script..."
    if [ -f "$install_dir/install.sh" ]; then
        bash "$install_dir/install.sh"
    else
        log_error "install.sh not found."
        return 1
    fi
    
    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "ShakeTune" "git_repo" "$install_dir" "https://github.com/Frix-x/klippain-shaketune.git" "klipper"
    fi
    
    log_success "ShakeTune installed."
    echo "  [!] Initialize with 'AXES_MAP_CALIBRATION' in Klipper."
    read -r -p "  Press Enter..."
}

function remove_shaketune() {
    draw_header "REMOVE SHAKETUNE"
    echo ""
    
    local install_dir="$HOME/klippain_shaketune"
    local venv_dir="$HOME/klippain_shaketune-env"
    
    if [ ! -d "$install_dir" ]; then
        log_warn "ShakeTune is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove ShakeTune completely? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    log_info "Removing ShakeTune..."
    rm -rf "$install_dir" "$venv_dir"
    rm -f "$HOME/klipper/klippy/extras/shaketune.py"
    
    log_success "ShakeTune removed!"
    read -r -p "  Press Enter..."
}

# ============================================================
# 2. LOG2RAM
# ============================================================
function install_log2ram() {
    draw_header "INSTALL LOG2RAM"
    echo "  Extends SD card life by writing logs to RAM first."
    echo ""
    
    if dpkg -s log2ram >/dev/null 2>&1; then
        log_warn "Log2Ram is already installed."
        read -r -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    fi
    
    log_info "Adding Repository..."
    echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
    sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg https://azlux.fr/repo.gpg
    
    log_info "Installing Log2Ram..."
    sudo apt-get update
    sudo apt-get install -y log2ram || {
        log_error "Failed to install log2ram"
        return 1
    }
    
    log_success "Log2Ram installed."
    echo "  [!] A reboot is required to activate."
    read -r -p "  Press Enter..."
}

function remove_log2ram() {
    draw_header "REMOVE LOG2RAM"
    
    if ! dpkg -s log2ram >/dev/null 2>&1; then
        log_warn "Log2Ram is not installed."
        read -r -p "  Press Enter..."
        return
    fi
    
    read -r -p "  Remove Log2Ram? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Removing Log2Ram..."
    sudo apt-get remove -y log2ram
    log_success "Log2Ram removed."
    read -r -p "  Press Enter..."
}

# ============================================================
# 3. TUNING MENU
# ============================================================
function run_tuning_menu() {
    while true; do
        draw_header "TUNING & SYSTEM TOOLS"
        
        local st="NOT INSTALLED"
        if [ -d "$HOME/klippain_shaketune" ]; then st="${C_GREEN}INSTALLED${NC}"; fi
        
        local l2r="NOT INSTALLED"
        if dpkg -s log2ram >/dev/null 2>&1; then l2r="${C_GREEN}INSTALLED${NC}"; fi
        
        echo ""
        echo "  --- Install ---"
        echo "  ${C_NEON}[1]${NC}  ShakeTune (Input Shaper) [$st]"
        echo "  ${C_NEON}[2]${NC}  Log2Ram (SD Saver)       [$l2r]"
        echo ""
        echo "  --- Remove ---"
        echo "  ${C_RED}[3]${NC}  Remove ShakeTune"
        echo "  ${C_RED}[4]${NC}  Remove Log2Ram"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " ch
        
        case $ch in
            1) install_shaketune ;;
            2) install_log2ram ;;
            3) remove_shaketune ;;
            4) remove_log2ram ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

#!/bin/bash
# ==============================================================================
# KATANA MODULE: Hardware Extensions Menu
# Routes to actual implementations in extras/ modules.
# ==============================================================================

function run_hardware_menu() {
    while true; do
        draw_header "HARDWARE EXTENSIONS"
        echo ""
        echo "  --- Toolchangers & Multi-Material ---"
        echo "  ${C_NEON}[1]${NC}  Multi-Material Menu  (Happy Hare, StealthChanger, MADMAX)"
        echo ""
        echo "  --- Probes / Z-Sensors ---"
        echo "  ${C_NEON}[2]${NC}  Smart Probe Menu     (Beacon, Cartographer, BTT Eddy)"
        echo "  ${C_NEON}[3]${NC}  Bed Distance Sensor"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> SELECT: " ch
        
        case $ch in
            1) run_multimaterial_menu ;;
            2) run_smartprobe_menu ;;
            3) install_bed_distance_sensor ;;
            [bB]) return ;;
            *) log_error "Invalid Selection." ;;
        esac
    done
}

# ============================================================
# BED DISTANCE SENSOR (Reference: markniu/Bed_Distance_sensor)
# ============================================================
function install_bed_distance_sensor() {
    draw_header "BED DISTANCE SENSOR"
    echo ""
    echo "  Reference: https://github.com/markniu/Bed_Distance_sensor"
    echo ""
    echo "  Accelerometer-based probe for automatic Z-offset calibration."
    echo ""
    read -r -p "  Install Bed Distance Sensor? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local repo_dir="$HOME/Bed_Distance_sensor"
    local cfg_dir="$HOME/printer_data/config/bed_distance_sensor"
    
    if [ -d "$repo_dir" ]; then
        log_warn "Bed Distance Sensor already installed."
        read -r -p "  Reinstall? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
        rm -rf "$repo_dir"
    fi
    
    log_info "Cloning Bed Distance Sensor..."
    git clone https://github.com/markniu/Bed_Distance_sensor.git "$repo_dir" || {
        log_error "Failed to clone."
        return 1
    }
    
    mkdir -p "$cfg_dir"
    if [ -d "$repo_dir/klipper_config" ]; then
        cp -r "$repo_dir/klipper_config/"* "$cfg_dir/"
        log_info "Configs copied to $cfg_dir"
    fi
    
    # Add include to printer.cfg
    local pcfg="$HOME/printer_data/config/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "bed_distance_sensor" "$pcfg"; then
            cp "$pcfg" "$pcfg.bak"
            echo "" >> "$pcfg"
            echo "# --- Bed Distance Sensor ---" >> "$pcfg"
            echo "[include bed_distance_sensor/*.cfg]" >> "$pcfg"
        fi
    fi
    
    if declare -f add_update_manager_entry > /dev/null; then
        add_update_manager_entry "BDS" "git_repo" "$repo_dir" "https://github.com/markniu/Bed_Distance_sensor.git" "klipper"
    fi
    
    log_success "Bed Distance Sensor installed!"
    echo "  Repo: $repo_dir"
    echo "  Configs: $cfg_dir"
    echo "  [!] Adjust pin settings for your setup."
    read -r -p "  Press Enter..."
}

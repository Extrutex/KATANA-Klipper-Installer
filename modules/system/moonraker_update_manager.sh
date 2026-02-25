#!/bin/bash
# ==============================================================================
# KATANA MODULE: Moonraker Update Manager Helper
# Automatically adds components to moonraker.conf for update management
# ==============================================================================

# Simple log functions (standalone usage)
log_info() { echo -e "  [INFO] $1"; }
log_success() { echo -e "  [OK] $1"; }

function add_update_manager_entry() {
    local name="$1"
    local type="$2"  # git_repo or web
    local path="$3"
    local origin="$4"
    local managed_services="${5:-}"
    local channel="${6:-stable}"
    local repo="${7:-}"
    
    local moonraker_conf="$HOME/printer_data/config/moonraker.conf"
    
    # Init moonraker.conf if missing
    if [ ! -f "$moonraker_conf" ]; then
        mkdir -p "$(dirname "$moonraker_conf")"
        touch "$moonraker_conf"
    fi
    
    # Check if entry already exists (Strict Check)
    # Check for existing section
    if grep -Fq "[update_manager $name]" "$moonraker_conf"; then
        log_info "Update manager entry for '$name' already exists. Skipping."
        return 0
    fi
    
    # Add entry
    echo "" >> "$moonraker_conf"
    echo "[update_manager $name]" >> "$moonraker_conf"
    
    if [ "$type" = "git_repo" ]; then
        echo "type: git_repo" >> "$moonraker_conf"
        echo "path: $path" >> "$moonraker_conf"
        echo "origin: $origin" >> "$moonraker_conf"
        if [ -n "$managed_services" ]; then
            echo "managed_services: $managed_services" >> "$moonraker_conf"
        fi
    elif [ "$type" = "web" ]; then
        echo "type: web" >> "$moonraker_conf"
        echo "channel: $channel" >> "$moonraker_conf"
        echo "repo: $repo" >> "$moonraker_conf"
        echo "path: $path" >> "$moonraker_conf"
    fi
    
    log_success "Added '$name' to Moonraker Update Manager."
}

# ============================================================
# Convenience functions for common components
# ============================================================

function register_shaketune_updates() {
    add_update_manager_entry "ShakeTune" "git_repo" \
        "$HOME/klippain_shaketune" \
        "https://github.com/Frix-x/klippain-shaketune.git" \
        "klipper"
}

function register_stealthchanger_updates() {
    add_update_manager_entry "StealthChanger" "git_repo" \
        "$HOME/printer_data/config/stealthchanger" \
        "https://github.com/DraftShift/StealthChanger.git" \
        "klipper"
}

function register_madmax_updates() {
    add_update_manager_entry "MADMAX" "git_repo" \
        "$HOME/printer_data/config/madmax" \
        "https://github.com/zruncho3d/madmax.git" \
        "klipper"
}

function register_cartographer_updates() {
    add_update_manager_entry "Cartographer" "git_repo" \
        "$HOME/cartographer-klipper" \
        "https://github.com/Cartographer3D/Cartographer-Klipper.git" \
        "klipper"
}

function register_beacon_updates() {
    add_update_manager_entry "Beacon" "git_repo" \
        "$HOME/beacon" \
        "https://github.com/beacon3d/BeaconKlipper.git" \
        "klipper"
}

function register_btt_eddy_updates() {
    add_update_manager_entry "BTT_Eddy" "git_repo" \
        "$HOME/Eddy" \
        "https://github.com/bigtreetech/Eddy.git" \
        "klipper"
}

function register_bed_distance_sensor_updates() {
    add_update_manager_entry "BedDistanceSensor" "git_repo" \
        "$HOME/bed_distance_sensor" \
        "https://github.com/markniu/Bed_Distance_sensor.git" \
        "klipper"
}

function register_katana_flow_updates() {
    add_update_manager_entry "KATANA-FLOW" "git_repo" \
        "$HOME/printer_data/config/katana_flow" \
        "https://github.com/YourRepo/KATANA-Klipper-Installer.git" \
        "klipper"
}

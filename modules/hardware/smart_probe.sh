#!/bin/bash
# ==============================================================================
# KATANA MODULE: Smart Probe Selector
# Advanced Support for Beacon3D and Cartographer
# ==============================================================================

function install_smart_probe() {
    while true; do
        draw_header "SMART PROBES (SCANNER/COIL)"
        echo "  Install modern eddy current sensors."
        echo "  [!] WARNING: These probes require 'udev' rules."
        echo "      KATANA will backup existing rules before installing."
        echo ""
        echo "  1) Install Beacon3D (Rev H/D)"
        echo "  2) Install Cartographer3D"
        echo "  B) Back"
        
        read -p "  >> SELECT PROBE: " ch
        case $ch in
            1) do_install_beacon ;;
            2) do_install_cartographer ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function do_install_beacon() {
    log_info "Installing Beacon3D..."
    
    # 1. Clone Repo
    local beacon_dir="$HOME/beacon_klipper"
    if [ -d "$beacon_dir" ]; then
        log_info "Updating Beacon repo..."
        cd "$beacon_dir" && git pull
    else
        git clone https://github.com/beacon3d/beacon_klipper.git "$beacon_dir"
    fi
    
    # 2. Run Installer
    log_info "Running Beacon install.sh..."
    cd "$beacon_dir" || return
    ./install.sh
    
    log_success "Beacon3D installed. Add '[beacon]' to your printer.cfg."
    read -p "  Press [Enter]..."
}

function do_install_cartographer() {
    log_info "Installing Cartographer3D..."
    
    # 1. Clone Repo
    local carto_dir="$HOME/cartographer-klipper"
    if [ -d "$carto_dir" ]; then
        log_info "Updating Cartographer repo..."
        cd "$carto_dir" && git pull
    else
        git clone https://github.com/Cartographer3D/cartographer-klipper.git "$carto_dir"
    fi
    
    # 2. Run Installer
    log_info "Running Cartographer install.sh..."
    cd "$carto_dir" || return
    ./install.sh
    
    log_success "Cartographer3D installed. Add '[cartographer]' to your printer.cfg."
    read -p "  Press [Enter]..."
}

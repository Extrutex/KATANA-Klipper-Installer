#!/bin/bash
# ==============================================================================
# KATANA MODULE: UNINSTALLER
# Complete removal of Klipper stack
# ==============================================================================

function run_uninstaller() {
    while true; do
        draw_header "KATANA UNINSTALLER"
        echo ""
        echo "  ⚠️  WARNING: This will remove ALL Klipper-related services!"
        echo ""
        echo "  [1] FULL UNINSTALL (Klipper + Moonraker + Nginx + WebUI)"
        echo "  [2] UNINSTALL KLIPPER ONLY"
        echo "  [3] UNINSTALL MOONRAKER ONLY"
        echo "  [4] UNINSTALL WEBUI (Mainsail/Fluidd)"
        echo "  [5] REMOVE ALL KATANA FILES"
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " cmd
        
        case $cmd in
            1) full_uninstall ;;
            2) uninstall_klipper ;;
            3) uninstall_moonraker ;;
            4) uninstall_webui ;;
            5) remove_katana_files ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function full_uninstall() {
    log_warn "This will remove EVERYTHING. Are you sure?"
    echo "  Type 'YES' to confirm: "
    read -r confirm
    
    if [ "$confirm" != "YES" ]; then
        log_info "Cancelled."
        return
    fi
    
    log_info "Stopping all services..."
    sudo systemctl stop klipper moonraker 2>/dev/null
    
    uninstall_webui
    uninstall_nginx
    uninstall_moonraker
    uninstall_klipper
    
    log_success "Full uninstall complete."
    read -p "  Press Enter..."
}

function uninstall_klipper() {
    log_info "Uninstalling Klipper..."
    
    # Stop and disable service
    sudo systemctl stop klipper 2>/dev/null
    sudo systemctl disable klipper 2>/dev/null
    sudo rm -f /etc/systemd/system/klipper.service
    sudo systemctl daemon-reload
    
    # Remove files
    rm -rf "$HOME/klipper"
    rm -rf "$HOME/klippy-env"
    rm -rf "$HOME/printer_data"
    
    log_success "Klipper uninstalled."
    read -p "  Press Enter..."
}

function uninstall_moonraker() {
    log_info "Uninstalling Moonraker..."
    
    # Stop and disable service
    sudo systemctl stop moonraker 2>/dev/null
    sudo systemctl disable moonraker 2>/dev/null
    sudo rm -f /etc/systemd/system/moonraker.service
    sudo systemctl daemon-reload
    
    # Remove files
    rm -rf "$HOME/moonraker"
    rm -rf "$HOME/.moonraker"
    
    log_success "Moonraker uninstalled."
    read -p "  Press Enter..."
}

function uninstall_webui() {
    log_info "Uninstalling WebUI..."
    
    # Stop Nginx
    sudo systemctl stop nginx 2>/dev/null
    
    # Remove Mainsail
    rm -rf "$HOME/mainsail"
    
    # Remove Fluidd
    rm -rf "$HOME/fluidd"
    
    # Remove HORIZON
    rm -rf "$HOME/horizon"
    
    # Remove Nginx config
    sudo rm -f /etc/nginx/sites-enabled/katana
    sudo rm -f /etc/nginx/sites-enabled/mainsail
    sudo rm -f /etc/nginx/sites-enabled/fluidd
    sudo rm -f /etc/nginx/sites-available/katana
    sudo rm -f /etc/nginx/sites-available/mainsail
    sudo rm -f /etc/nginx/sites-available/fluidd
    
    sudo systemctl restart nginx 2>/dev/null
    
    log_success "WebUI uninstalled."
    read -p "  Press Enter..."
}

function uninstall_nginx() {
    log_info "Uninstalling Nginx..."
    
    sudo systemctl stop nginx 2>/dev/null
    sudo apt-get remove -y nginx nginx-light nginx-full 2>/dev/null
    sudo apt-get autoremove -y 2>/dev/null
    
    log_success "Nginx uninstalled."
}

function remove_katana_files() {
    log_info "Removing all KATANA files..."
    
    rm -rf "$HOME/KATANA-Klipper-Installer"
    rm -rf "$HOME/katana_diagnostics"
    rm -f "$HOME/katana.log"
    
    # Remove from PATH if added
    sed -i '/katanaos.sh/d' "$HOME/.bashrc" 2>/dev/null
    
    log_success "KATANA files removed."
    read -p "  Press Enter..."
}

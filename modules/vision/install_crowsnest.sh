#!/bin/bash
# modules/vision/install_crowsnest.sh

# Source KlipperScreen installer
source "$MODULES_DIR/extras/install_klipperscreen.sh"

function install_vision_stack() {
    while true; do
        draw_header "HMI & VISION STACK"
        echo ""
        echo "  [1] Crowsnest      - Webcam Streamer (Recommended)"
        echo "  [2] KlipperScreen - Touch Display Interface"
        echo ""
        echo "  [R] Remove Crowsnest"
        echo "  [K] Remove KlipperScreen"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> " ch
        
        case $ch in
            1) do_install_crowsnest ;;
            2) install_klipperscreen ;;
            r|R) do_remove_crowsnest ;;
            k|K) do_remove_klipperscreen ;;
            b|B) return ;;
        esac
    done
}

function do_install_crowsnest() {
    log_info "Installing Crowsnest..."
    
    local repo_dir="$HOME/crowsnest"
    if [ -d "$repo_dir" ]; then
        log_info "Crowsnest repo exists. Pulling..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning Crowsnest" "git clone https://github.com/mainsail-crew/crowsnest.git $repo_dir"
    fi
    
    cd "$repo_dir"
    log_info "Running Crowsnest Installer..."
    
    if sudo -n true 2>/dev/null; then
        make install
    else
        echo "  [!] Sudo required for Crowsnest."
        make install
    fi
    
    log_success "Crowsnest Installed."
    read -p "  Press Enter..."
}

function do_remove_crowsnest() {
    log_info "Removing Crowsnest..."
    cd "$HOME/crowsnest" 2>/dev/null && make uninstall
    rm -rf "$HOME/crowsnest"
    log_success "Crowsnest Removed."
    read -p "  Press Enter..."
}

function do_remove_klipperscreen() {
    log_info "Removing KlipperScreen..."
    cd "$HOME/KlipperScreen" 2>/dev/null && make uninstall
    rm -rf "$HOME/KlipperScreen"
    sudo rm -f /etc/systemd/system/KlipperScreen.service
    sudo systemctl daemon-reload
    log_success "KlipperScreen Removed."
    read -p "  Press Enter..."
}

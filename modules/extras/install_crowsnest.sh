#!/bin/bash

function install_crowsnest() {
    log_info "Installing Crowsnest (Webcam Streamer)..."
    
    local repo_dir="$HOME/crowsnest"
    
    # 1. Clone
    if [ -d "$repo_dir" ]; then
        log_info "Crowsnest Repo exists. Updating..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning Crowsnest" "git clone https://github.com/mainsail-crew/crowsnest.git $repo_dir"
    fi
    
    # 2. Install (using their installer for reliability, but wrapped)
    log_info "Running Crowsnest Installer..."
    # Crowsnest has a good Makefile/installer, let's use it but control the output
    cd "$repo_dir"
    
    # Actually, Crowsnest install is best done via their install.sh if available, OR standard make install
    
    if [ -f "$repo_dir/Makefile" ]; then
        if sudo make install; then
             log_success "Crowsnest Installed."
        else
             log_error "Crowsnest Make Install failed."
        fi
    else
        log_error "Makefile not found in Crowsnest repo."
    fi
    
    # 3. Default Config
    if [ ! -f "$HOME/printer_data/config/crowsnest.conf" ]; then
        log_info "Creating default crowsnest.conf..."
        cp "$repo_dir/tools/crowsnest.conf" "$HOME/printer_data/config/crowsnest.conf" 2>/dev/null || echo "[crowsnest] logic..." > "$HOME/printer_data/config/crowsnest.conf"
        log_success "Config created."
    fi
    
    read -p "  Press Enter..."
}

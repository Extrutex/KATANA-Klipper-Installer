#!/bin/bash

function do_install_klipperscreen() {
    log_info "Installing KlipperScreen (Touch Interface)..."

    local repo_dir="$HOME/KlipperScreen"

    # 1. Clone
    if [ -d "$repo_dir" ]; then
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning KlipperScreen" "git clone https://github.com/KlipperScreen/KlipperScreen.git $repo_dir"
    fi

    # 2. Dependency Scripts
    # KlipperScreen has a robust install script
    log_info "Running KlipperScreen Install Script..."
    
    # Needs system packages so we might need sudo
    cd "$repo_dir/scripts"
    
    # Runs venv + systemd setup
    if ./KlipperScreen-install.sh; then
        log_success "KlipperScreen Installed."
    else
        log_error "KlipperScreen Install failed. Check logs."
    fi

    read -p "  Press Enter..."
}

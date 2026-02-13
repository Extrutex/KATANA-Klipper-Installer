#!/bin/bash

function run_hardening_wizard() {
    draw_header "SYSTEM HARDENING"
    echo "  This wizard will:"
    echo "  1. Enable UFW Firewall (SSH/HTTP/API allowed)"
    echo "  2. Check/Install Log2Ram (Save SD Card life)"
    echo ""
    read -p "  Start Hardening? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi

    # 1. Firewall
    log_info "Configuring UFW Firewall..."
    # Policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    # Allow rules
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https # Just in case
    sudo ufw allow 7125  # Moonraker
    sudo ufw allow 8080  # Crowsnest Stream
    
    # Enable
    echo "y" | sudo ufw enable
    log_success "Firewall active."

    # 2. Log2Ram
    log_info "Checking Log2Ram..."
    if dpkg -s log2ram >/dev/null 2>&1; then
        log_success "Log2Ram is already installed."
    else
        log_info "Installing Log2Ram..."
        # Add repo and install
        echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
        sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
        sudo apt update
        sudo apt install -y log2ram
        log_success "Log2Ram installed."
    fi

    read -p "  Hardening Complete. Press [Enter]..."
}

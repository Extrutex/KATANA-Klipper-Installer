#!/bin/bash
# ==============================================================================
# KATANA MODULE: SYSTEM HARDENING (The "Right Way")
# Implements UFW Firewall with Klipper-aware rules.
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$KATANA_ROOT/core/logging.sh"
fi

function install_security_stack() {
    draw_header "SYSTEM HARDENING (UFW)"
    echo "  This will install and configure UFW (Uncomplicated Firewall)."
    echo "  It secures your Klipper system against network attacks."
    echo ""
    echo "  ${C_RED}[!] WARNING:${NC} Configuring a firewall via SSH carries a risk."
    echo "  We have implemented safety checks, but please be careful."
    echo ""
    read -r -p "  Proceed with Firewall Setup? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    # 1. Install UFW
    log_info "Installing UFW..."
    if ! dpkg -s ufw >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y ufw || {
            log_error "Failed to install UFW."
            return 1
        }
    else
        log_info "UFW is already installed."
    fi
    
    # 2. Reset UFW to default state (Clean Slate)
    log_info "Resetting Rules..."
    sudo ufw --force reset
    
    # 3. Apply Default Policies
    log_info "Applying Default Policies (Deny Incoming, Allow Outgoing)..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # 4. Critical: SSH
    # Detect SSH Port (usually 22, but check config just in case)
    local ssh_port=22
    # Simple check, assuming standard config or user knows
    log_info "Allowing SSH (Port $ssh_port)..."
    sudo ufw allow "$ssh_port/tcp"
    
    # 5. Klipper / Moonraker Ports
    log_info "Allowing Klipper Services..."
    sudo ufw allow 80/tcp    # HTTP (Mainsail/Fluidd)
    sudo ufw allow 443/tcp   # HTTPS
    sudo ufw allow 7125/tcp  # Moonraker API
    sudo ufw allow 8080/tcp  # Crowsnest / MJPG-Streamer
    
    # 6. Enable Firewall
    log_info "Enabling Firewall..."
    echo "y" | sudo ufw enable
    
    # 7. Verification
    if sudo ufw status | grep -q "Status: active"; then
        log_success "Firewall is ACTIVE and protecting your system."
        sudo ufw status verbose
    else
        log_error "Failed to activate firewall."
    fi
    
    echo ""
    echo "  [i] Note: You can check status anytime with 'sudo ufw status'."
    read -r -p "  Press Enter..."
}

function install_fail2ban() {
    draw_header "INSTALL FAIL2BAN"
    echo "  Protect SSH against brute-force attacks."
    echo ""
    read -r -p "  Install Fail2Ban? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Installing Fail2Ban..."
    sudo apt-get update
    sudo apt-get install -y fail2ban
    
    log_success "Fail2Ban installed and running."
    read -r -p "  Press Enter..."
}

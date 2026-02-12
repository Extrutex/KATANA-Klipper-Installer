#!/bin/bash

function install_security_stack() {
    draw_header "SECURITY SHIELD"
    echo "  1) Enable Firewall (UFW)"
    echo "  2) Generate Backup"
    echo "  B) Back"
    read -p "  >> " ch
    
    case $ch in
        1) setup_firewall ;;
        2) perform_backup ;;
        [bB]) return ;;
    esac
}

function setup_firewall() {
    log_info "Setting up UFW..."
    # Default Policy: Allow SSH, HTTP, 7125. Deny rest.
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow 7125
    sudo ufw enable
    log_success "Firewall enabled."
    read -p "  Press Enter..."
}

function perform_backup() {
    log_info "Manual Backup Triggered..."
    # Could call backup_manager.sh
    log_success "Backup logic placeholder."
    read -p "  Press Enter..."
}

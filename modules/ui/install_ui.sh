#!/bin/bash
# modules/ui/install_ui.sh

# Source Deployment Module
source "$KATANA_ROOT/modules/system/deploy_webui.sh"

function install_ui_stack() {
    while true; do
        draw_header "🌐 WEB INTERFACE MANAGER"
        echo ""
        echo "  [1] Install Mainsail"
        echo "  [2] Install Fluidd"
        echo ""
        echo "  --- Uninstall / Reinstall ---"
        echo "  [3] Uninstall Mainsail"
        echo "  [4] Uninstall Fluidd"
        echo "  [5] Uninstall ALL UIs"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) do_install_mainsail ;;
            2) do_install_fluidd ;;
            3) uninstall_mainsail ;;
            4) uninstall_fluidd ;;
            5) uninstall_all_ui ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function do_install_mainsail() {
    log_info "Installing Mainsail..."
    
    # Logic to download/install mainsail
    # Simplified placeholder logic as real logic was likely lost or needs to be robust
    local install_dir="$HOME/mainsail"
    if [ -d "$install_dir" ]; then
        log_warn "Mainsail already exists at $install_dir"
    else
        log_info "Cloning Mainsail..."
        # In reality, mainsail is usually a zip release, not a clone for the build
        # But for KIAUH replacement, we usually fetch the latest release.
        # For now, I will use a standard creating directory method.
        mkdir -p "$install_dir"
        # Download latest release (simulated for stability/explanation)
        wget -q -O mainsail.zip https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip
        unzip -q mainsail.zip -d "$install_dir"
        rm mainsail.zip
        log_success "Mainsail downloaded."
    fi
    
    # Configure Nginx
    setup_nginx "mainsail"
    
    log_success "Mainsail Installed."
    read -p "  Press Enter..."
}

function do_install_fluidd() {
    log_info "Installing Fluidd..."
    local install_dir="$HOME/fluidd"
     if [ -d "$install_dir" ]; then
        log_warn "Fluidd already exists at $install_dir"
    else
        mkdir -p "$install_dir"
        wget -q -O fluidd.zip https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip
        unzip -q fluidd.zip -d "$install_dir"
        rm fluidd.zip
        log_success "Fluidd downloaded."
    fi
    
    # Configure Nginx
    setup_nginx "fluidd"
    
    log_success "Fluidd Installed."
    read -p "  Press Enter..."
}



function uninstall_mainsail() {
    draw_header "UNINSTALL MAINSAIL"
    echo ""
    read -p "  Uninstall Mainsail? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    log_info "Removing Mainsail..."
    rm -rf "$HOME/mainsail"
    sudo rm -f /etc/nginx/sites-enabled/mainsail /etc/nginx/sites-available/mainsail
    sudo systemctl restart nginx
    draw_success "Mainsail uninstalled."
    read -p "  Press Enter..."
}

function uninstall_fluidd() {
    draw_header "UNINSTALL FLUIDD"
    echo ""
    read -p "  Uninstall Fluidd? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    log_info "Removing Fluidd..."
    rm -rf "$HOME/fluidd"
    sudo rm -f /etc/nginx/sites-enabled/fluidd /etc/nginx/sites-available/fluidd
    sudo systemctl restart nginx
    draw_success "Fluidd uninstalled."
    read -p "  Press Enter..."
}

function uninstall_all_ui() {
    draw_header "UNINSTALL ALL UIs"
    echo ""
    read -p "  Uninstall ALL web interfaces? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    log_info "Removing all UIs..."
    rm -rf "$HOME/mainsail" "$HOME/fluidd" "$HOME/horizon"
    sudo rm -f /etc/nginx/sites-enabled/mainsail /etc/nginx/sites-available/mainsail
    sudo rm -f /etc/nginx/sites-enabled/fluidd /etc/nginx/sites-available/fluidd
    sudo systemctl restart nginx
    draw_success "All UIs uninstalled."
    read -p "  Press Enter..."
}

function do_remove_ui() {
    log_info "Removing UI..."
    rm -rf "$HOME/mainsail" "$HOME/fluidd"
    log_success "UI Removed."
    read -p "  Press Enter..."
}

function setup_nginx() {
    local ui_type="$1" # mainsail or fluidd
    log_info "Configuring Nginx for $ui_type..."
    
    # Check if nginx is installed
    if ! command -v nginx &> /dev/null; then
        if sudo -n true 2>/dev/null; then
            sudo apt-get install -y nginx
        else
            echo "  [!] Sudo required to install nginx."
            sudo apt-get install -y nginx
        fi
    fi
    
    # Create nginx config
    local cfg_file="/etc/nginx/sites-available/$ui_type"
    local root_dir="$HOME/$ui_type"
    
    # Create proper nginx config with all needed locations
    sudo tee "$cfg_file" > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    access_log /var/log/nginx/klipper_access.log;
    error_log /var/log/nginx/klipper_error.log;

    client_max_body_size 100M;

    location / {
        root $root_dir;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /access {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /server {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /websocket {
        proxy_pass http://localhost:7125;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }

    location /webcam {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location ~ ^/(printer|gcodes|timelapse) {
        proxy_pass http://localhost:7125;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Remove old default and link new
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -sf "$cfg_file" /etc/nginx/sites-enabled/
    
    # Test & Reload
    sudo nginx -t && sudo systemctl reload nginx
    
    log_success "Nginx configured for $ui_type."
}

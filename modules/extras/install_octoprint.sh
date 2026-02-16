#!/bin/bash
# ==============================================================================
# KATANA OCTOPRINT INSTALLER
# ==============================================================================

function run_octoprint_menu() {
    while true; do
        draw_header "OCTOPRINT INSTALLER"
        
        echo "  [1] Install OctoPrint"
        echo "  [2] Install OctoPrint + Klipper Plugin"
        echo "  [3] Remove OctoPrint"
        echo "  [4] Restart OctoPrint"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> " ch
        
        case $ch in
            1) install_octoprint ;;
            2) install_octoprint_with_klipper ;;
            3) remove_octoprint ;;
            4) restart_octoprint ;;
            b|B) return ;;
        esac
    done
}

function install_octoprint() {
    draw_header "INSTALLING OCTOPRINT"
    
    log_info "Installing Python and OctoPrint dependencies..."
    
    # Check if already installed
    if [ -d "$HOME/.octoprint" ]; then
        log_warn "OctoPrint already installed. Updating..."
    fi
    
    # Install system dependencies
    if sudo -n true 2>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3-pip python3-dev python3-setuptools \
            virtualenv libyaml-dev libffi-dev libssl-dev
    else
        echo "  [!] Sudo required. Enter password when prompted."
        sudo apt-get update
        sudo apt-get install -y python3-pip python3-dev python3-setuptools \
            virtualenv libyaml-dev libffi-dev libssl-dev
    fi
    
    # Create virtual environment
    log_info "Creating Python virtual environment..."
    cd "$HOME"
    virtualenv -p python3 OctoPrint/venv || python3 -m venv OctoPrint/venv
    
    # Install OctoPrint
    log_info "Installing OctoPrint..."
    if [ -f "OctoPrint/venv/bin/pip" ]; then
        OctoPrint/venv/bin/pip install --upgrade pip
        OctoPrint/venv/bin/pip install OctoPrint
    else
        . OctoPrint/venv/bin/activate
        pip install --upgrade pip
        pip install OctoPrint
    fi
    
    # Create systemd service
    create_octoprint_service
    
    log_success "OctoPrint installed!"
    echo "  Access at: http://$(hostname).local:5000"
    read -p "  Press Enter..."
}

function install_octoprint_with_klipper() {
    install_octoprint
    
    log_info "Installing OctoPrint-Klipper plugin..."
    if [ -f "$HOME/OctoPrint/venv/bin/pip" ]; then
        $HOME/OctoPrint/venv/bin/pip install octoprint_klipper
    else
        . $HOME/OctoPrint/venv/bin/activate
        pip install octoprint_klipper
    fi
    
    log_success "OctoPrint + Klipper plugin installed!"
    read -p "  Press Enter..."
}

function create_octoprint_service() {
    cat > /tmp/octoprint.service <<EOF
[Unit]
Description=OctoPrint Service
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME
Environment="PATH=$HOME/OctoPrint/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$HOME/OctoPrint/venv/bin/octoprint serve --host=0.0.0.0 --port=5000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    if sudo -n true 2>/dev/null; then
        sudo cp /tmp/octoprint.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable octoprint
        sudo systemctl start octoprint
    else
        echo "  [!] Sudo required to install service."
        sudo cp /tmp/octoprint.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable octoprint
        sudo systemctl start octoprint
    fi
    
    rm -f /tmp/octoprint.service
}

function remove_octoprint() {
    log_info "Removing OctoPrint..."
    
    sudo systemctl stop octoprint 2>/dev/null
    sudo systemctl disable octoprint 2>/dev/null
    sudo rm -f /etc/systemd/system/octoprint.service
    
    rm -rf "$HOME/OctoPrint"
    
    log_success "OctoPrint removed."
    read -p "  Press Enter..."
}

function restart_octoprint() {
    log_info "Restarting OctoPrint..."
    sudo systemctl restart octoprint
    log_success "OctoPrint restarted."
    read -p "  Press Enter..."
}

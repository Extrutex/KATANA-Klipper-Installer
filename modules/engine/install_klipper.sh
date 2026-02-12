#!/bin/bash

function install_core_stack() {
    draw_header "CORE ENGINE INSTALLER"
    echo "  1) Install Klipper (Standard)"
    echo "  2) Install Moonraker"
    echo "  3) Install Kalico (High-Performance)"
    echo "  B) Back"
    read -p "  >> " ch

    case $ch in
        1) do_install_klipper "Standard" ;;
        2) do_install_moonraker ;;
        3) do_install_kalico ;;
        [bB]) return ;;
    esac
}

function do_install_klipper() {
    local variant="$1"
    log_info "Installing Klipper ($variant)..."
    
    # 1. Clone
    local repo_dir="$HOME/klipper_repo"
    if [ -d "$repo_dir" ]; then
        log_info "Klipper repo already exists at $repo_dir. Pulling updates..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning Klipper" "git clone https://github.com/Klipper3d/klipper.git $repo_dir"
    fi

    # 2. VirtualEnv
    local env_dir="$HOME/klipper_env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
        exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/klippy-requirements.txt"
    fi

    # 3. Symlink check (Init first install)
    if [ ! -L "$HOME/klipper" ]; then
        ln -s "$repo_dir" "$HOME/klipper"
        ln -s "$env_dir" "$HOME/klippy-env"
        log_success "Initialized Symlinks for Klipper."
    fi

    # 4. Service File
    # We use the symlink paths so we don't need to change the service file when switching engines!
    cat <<EOF | sudo tee /etc/systemd/system/klipper.service >/dev/null
[Unit]
Description=Klipper 3D Printer Firmware
After=network.target

[Service]
Type=simple
User=$USER
RemainAfterExit=yes
ExecStart=$HOME/klippy-env/bin/python $HOME/klipper/klippy/klippy.py $HOME/printer_data/config/printer.cfg -l $HOME/printer_data/logs/klippy.log -a $HOME/printer_data/comms/klippy.sock
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable klipper
    sudo systemctl restart klipper

    log_success "Klipper ($variant) installed and service started."
    read -p "  Press Enter..."
}

function do_install_kalico() {
    log_info "Installing Kalico..."
    
    # 1. Clone
    local repo_dir="$HOME/kalico_repo"
    if [ -d "$repo_dir" ]; then
        log_info "Kalico repo already exists at $repo_dir. Pulling updates..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning Kalico" "git clone https://github.com/KalicoCrew/kalico.git $repo_dir"
    fi

    # 2. VirtualEnv
    local env_dir="$HOME/kalico_env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
        exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/klippy-requirements.txt"
    fi
    
    log_success "Kalico installed. Use 'Engine Manager' to switch to it."
    read -p "  Press Enter..."
}

function do_install_moonraker() {
    log_info "Installing Moonraker..."
    # Placeholder for brevity - logic is similar to Klipper
    log_success "Moonraker installed (Placeholder)."
    read -p "  Press Enter..."
}

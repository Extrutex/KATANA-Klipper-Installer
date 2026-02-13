#!/bin/bash

function install_core_stack() {
    draw_header "CORE ENGINE INSTALLER"
    echo "  1) Install Klipper (Standard)"
    echo "  2) Install Moonraker"
    echo "  3) Install Kalico (High-Performance)"
    echo "  4) Install RatOS (Klipper Fork)"
    echo "  B) Back"
    read -p "  >> " ch

    case $ch in
        1) do_install_klipper "Standard" ;;
        2) do_install_moonraker ;;
        3) do_install_kalico ;;
        4) do_install_ratos ;;
        [bB]) return ;;
    esac
}

function do_install_ratos() {
    log_info "Installing RatOS (Klipper Fork)..."
    
    # 1. Clone
    local repo_dir="$HOME/ratos_repo"
    if [ -d "$repo_dir" ]; then
        log_info "RatOS repo already exists. Pulling..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning RatOS" "git clone https://github.com/Rat-OS/klipper.git $repo_dir"
    fi

    # 2. VirtualEnv
    local env_dir="$HOME/ratos_env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
        exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/klippy-requirements.txt"
    fi
    
    log_success "RatOS installed. Use 'Engine Manager' to switch to it."
    read -p "  Press Enter..."
}

function do_install_klipper() {
    local variant="$1"
    log_info "Installing Klipper ($variant)..."
    
    # 0. System Dependencies (Robustness Fix)
    log_info "Ensuring Klipper System Dependencies..."
    local k_deps=("virtualenv" "python3-dev" "libffi-dev" "build-essential" "libncurses-dev" "libusb-dev" "avrdude" "gcc-avr" "binutils-avr" "avr-libc" "stm32flash" "libnewlib-arm-none-eabi" "gcc-arm-none-eabi" "binutils-arm-none-eabi" "libusb-1.0-0-dev")
    
    if sudo -n true 2>/dev/null; then
        sudo apt-get install -y "${k_deps[@]}"
    else
         echo "  [!] Sudo required for Klipper dependencies."
         sudo apt-get install -y "${k_deps[@]}"
    fi
    
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
    # Using KATANA Service Manager v2.0
    if command -v install_service_from_template &> /dev/null; then
        install_service_from_template "klipper"
    else
        # Fallback if manager not loaded
        log_warn "Service Manager not found. Using fallback."
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
    fi
    
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
    
    # 1. Dependencies (System)
    log_info "Installing System Dependencies for Moonraker..."
    # Common requirements for Moonraker
    local m_deps=("python3-virtualenv" "python3-dev" "liblmdb-dev" "libopenjp2-7" "libsodium-dev" "zlib1g-dev" "libjpeg-dev" "packagekit" "python3-wheel" "nginx")
    
    if sudo -n true 2>/dev/null; then
        sudo apt-get install -y "${m_deps[@]}"
    else
         echo "  [!] Sudo required for Moonraker dependencies."
         sudo apt-get install -y "${m_deps[@]}"
    fi

    # 2. Clone
    local repo_dir="$HOME/moonraker"
    if [ -d "$repo_dir" ]; then
        log_info "Moonraker repo exists. Pulling..."
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning Moonraker" "git clone https://github.com/Arksine/moonraker.git $repo_dir"
    fi

    # 3. VirtualEnv
    local env_dir="$HOME/moonraker-env"
    if [ ! -d "$env_dir" ]; then
        exec_silent "Creating VirtualEnv" "virtualenv -p python3 $env_dir"
        exec_silent "Installing Dependencies" "$env_dir/bin/pip install -r $repo_dir/scripts/moonraker-requirements.txt"
    fi

    # 4. Service File
    # Using KATANA Service Manager v2.0
    if command -v install_service_from_template &> /dev/null; then
        install_service_from_template "moonraker"
    else
         # Fallback
        cat <<EOF | sudo tee /etc/systemd/system/moonraker.service >/dev/null
[Unit]
Description=Moonraker API Server for Klipper
Requires=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER
SyslogIdentifier=moonraker
ExecStart=$HOME/moonraker-env/bin/python $HOME/moonraker/moonraker/moonraker.py -d $HOME/printer_data
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable moonraker
    fi
    
    sudo systemctl restart moonraker
    
    log_success "Moonraker installed and service started."
    read -p "  Press Enter..."
}

function update_core_stack() {
    draw_header "UPDATE KLIPPER & MOONRAKER"
    echo "  1) Update Klipper"
    echo "  2) Update Moonraker"
    echo "  3) Update Both"
    echo "  B) Back"
    read -p "  >> " ch

    case $ch in
        1) do_update_klipper ;;
        2) do_update_moonraker ;;
        3) do_update_klipper && do_update_moonraker ;;
        [bB]) return ;;
    esac
}

function do_update_klipper() {
    local klipper_dir="$HOME/klipper"
    
    if [ ! -d "$klipper_dir" ]; then
        log_error "Klipper not installed. Install it first."
        read -p "  Press Enter..."
        return 1
    fi

    log_info "Updating Klipper..."
    
    cd "$klipper_dir"
    
    # Check for updates
    local current_sha=$(git rev-parse HEAD)
    git fetch origin
    local latest_sha=$(git rev-parse origin/main)
    
    if [ "$current_sha" == "$latest_sha" ]; then
        log_success "Klipper is already up to date."
    else
        log_info "Updating from $(git rev-parse --short HEAD) to $(git rev-parse --short origin/main)..."
        git pull origin main
        
        # Rebuild
        log_info "Rebuilding Klipper..."
        make clean
        make -j$(nproc)
        
        # Restart service
        sudo systemctl restart klipper
        sleep 2
        
        if systemctl is-active --quiet klipper; then
            log_success "Klipper updated and restarted."
        else
            log_error "Klipper failed to start after update!"
        fi
    fi
    
    read -p "  Press Enter..."
}

function do_update_moonraker() {
    local moonraker_dir="$HOME/moonraker"
    
    if [ ! -d "$moonraker_dir" ]; then
        log_error "Moonraker not installed. Install it first."
        read -p "  Press Enter..."
        return 1
    fi

    log_info "Updating Moonraker..."
    
    cd "$moonraker_dir"
    
    # Check for updates
    local current_sha=$(git rev-parse HEAD)
    git fetch origin
    local latest_sha=$(git rev-parse origin/main)
    
    if [ "$current_sha" == "$latest_sha" ]; then
        log_success "Moonraker is already up to date."
    else
        log_info "Updating from $(git rev-parse --short HEAD) to $(git rev-parse --short origin/main)..."
        git pull origin main
        
        # Install requirements
        log_info "Installing dependencies..."
        pip install -r requirements.txt --upgrade
        
        # Restart service
        sudo systemctl restart moonraker
        sleep 2
        
        if systemctl is-active --quiet moonraker; then
            log_success "Moonraker updated and restarted."
        else
            log_error "Moonraker failed to start after update!"
        fi
    fi
    
    read -p "  Press Enter..."
}

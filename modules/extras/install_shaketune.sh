#!/bin/bash

function install_shaketune() {
    log_info "Installing Klippain ShakeTune..."
    
    local repo_dir="$HOME/klippain_shaketune"
    local venv_dir="$HOME/klippain_shaketune-env"
    
    # 1. Clone
    if [ -d "$repo_dir" ]; then
        cd "$repo_dir" && git pull
    else
        exec_silent "Cloning ShakeTune" "git clone https://github.com/Frix-x/klippain-shaketune.git $repo_dir"
    fi
    
    # 2. VirtualEnv & Install
    if [ ! -d "$venv_dir" ]; then
        exec_silent "Creating venv" "virtualenv -p python3 $venv_dir"
    fi
    
    exec_silent "Installing Requirements" "$venv_dir/bin/pip install -r $repo_dir/requirements.txt"
    
    # 3. Klipper Macro Extension
    log_info "Running Installation Script..."
    if [ -f "$repo_dir/install.sh" ]; then
         "$repo_dir/install.sh"
    else
         log_warn "Manual Install (Install script not found/simulated)"
         ln -sf "$repo_dir/shaketune.py" "$HOME/klipper/klippy/extras/shaketune.py"
         log_success "Symlink created."
    fi

    # 4. Add to Moonraker Update Manager
    register_shaketune_updates

    log_success "ShakeTune Installed."
    read -p "  Press Enter..."
}

#!/bin/bash

# --- Engine Manager ---
# Handles switching between Klipper and Kalico using Symlinks.

function run_engine_manager() {
    draw_header "ENGINE MANAGER"
    echo -e "  Current Engine: $(get_current_engine)"
    echo ""
    echo "  1) Switch to KLIPPER (Standard)"
    echo "  2) Switch to KALICO (High-Performance)"
    echo "  3) Switch to RatOS (Klipper Fork)"
    echo "  B) Back"
    read -r -p "  >> " ech
    
    case $ech in
        1) switch_core_router "klipper" ;;
        2) switch_core_router "kalico" ;;
        3) switch_core_router "ratos" ;;
        [bB]) return ;;
    esac
}

function switch_core_router() {
    local target="$1"
    switch_core "$target"
}

function get_current_engine() {
    if [ -L "$HOME/klipper" ]; then
        local target=$(readlink "$HOME/klipper")
        if [[ "$target" == *"kalico"* ]]; then
            echo "${C_GREEN}KALICO${C_RESET}"
        elif [[ "$target" == *"ratos"* ]]; then
             echo "${C_GREEN}RatOS${C_RESET}"
        elif [[ "$target" == *"klipper"* ]]; then
            echo "${C_CYAN}KLIPPER${C_RESET}"
        else
            echo "${C_WARN}UNKNOWN ($target)${C_RESET}"
        fi
    else
        echo "${C_RED}NOT INSTALLED${C_RESET}"
    fi
}

function switch_core() {
    local target="$1"
    local target_repo=""
    local target_env=""
    
    log_info "Initiating switch to: $target"

    if [ "$target" == "klipper" ]; then
        target_repo="$HOME/klipper_repo"
        target_env="$HOME/klipper_env"
    elif [ "$target" == "kalico" ]; then
        target_repo="$HOME/kalico_repo"
        target_env="$HOME/kalico_env"
    elif [ "$target" == "ratos" ]; then
        target_repo="$HOME/ratos_repo"
        target_env="$HOME/ratos_env"
    else
        log_error "Unknown target: $target"
        return 1
    fi

    # Check if target exists
    if [ ! -d "$target_repo" ]; then
        log_error "Target repo not found at $target_repo. Please install it first using the Installer menu."
        read -r -p "  Press Enter..."
        return 1
    fi

    # 1. Stop Service
    exec_silent "Stopping Klipper Service" "sudo systemctl stop klipper"

    # 2. Update Symlinks
    # ~/klipper -> repo
    if [ -L "$HOME/klipper" ] || [ -d "$HOME/klipper" ]; then
        rm -rf "$HOME/klipper"
    fi
    ln -s "$target_repo" "$HOME/klipper"
    
    # ~/klippy-env -> env
    if [ -L "$HOME/klippy-env" ] || [ -d "$HOME/klippy-env" ]; then
        rm -rf "$HOME/klippy-env"
    fi
    ln -s "$target_env" "$HOME/klippy-env"

    log_success "Symlinks redirected to $target."

    # 3. Restart Service
    exec_silent "Restarting Klipper Service" "sudo systemctl start klipper"
    
    log_success "Successfully switched to $target."
    read -r -p "  Press Enter..."
}

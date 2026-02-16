#!/bin/bash
# modules/engine/core_switcher_pro.sh
# KATANA Master Architect - Core Switching Module (Pro)

function switch_core_pro() {
    local target="$1"
    local target_repo=""
    local target_env=""
    
    draw_header "CORE SWITCH PRO: $target"
    
    # 1. Resolve Target Paths
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
    
    # 2. Validate Target
    if ! validate_target "$target_repo" "$target_env"; then
        log_error "Target validation failed. Aborting switch."
        read -p "  Press Enter..."
        return 1
    fi
    
    # 3. Request User Confirmation
    echo "  Target:  $target"
    echo "  Repo:    $target_repo"
    echo "  Env:     $target_env"
    echo ""
    echo "  [!] WARNING: This will temporarily stop your printer."
    read -p "  Proceed? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    # 4. Backup
    backup_configs
    
    # 5. Atomic Switch
    perform_atomic_switch "$target_repo" "$target_env" "$target"
}

function validate_target() {
    local repo="$1"
    local env="$2"
    
    log_info "Validating Target..."
    
    if [ ! -d "$repo" ]; then
        log_error "Repository not found: $repo"
        return 1
    fi
    
    if [ ! -d "$repo/.git" ]; then
        log_error "Invalid Git Repository: $repo"
        return 1
    fi
    
    if [ ! -d "$env" ]; then
         log_error "VirtualEnv not found: $env"
         return 1
    fi

    # Check for Python 3 (KATANA Requirement)
    if [ ! -f "$env/bin/python3" ]; then
        log_warn "VirtualEnv does not appear to be Python 3: $env"
        # We proceed but warn, as old envs might be structred differently
    fi
    
    log_success "Target Validated."
    return 0
}

function backup_configs() {
    log_info "Creating Config Snapshot..."
    local config_dir="$HOME/printer_data/config"
    local backup_dir="$HOME/printer_data/config/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot="$backup_dir/pre_switch_$timestamp"
    
    mkdir -p "$backup_dir"
    
    if [ -f "$config_dir/printer.cfg" ]; then
        cp "$config_dir/printer.cfg" "$snapshot.printer.cfg"
        log_success "Backup created: $snapshot.printer.cfg"
    else
        log_warn "No printer.cfg found to backup."
    fi
}

function perform_atomic_switch() {
    local repo="$1"
    local env="$2"
    local name="$3"
    
    log_info "Initiating Atomic Switch..."
    
    # A. Stop Service (only if exists and running)
    if systemctl list-unit-files klipper.service &>/dev/null; then
        if systemctl is-active --quiet klipper; then
            exec_silent "Stopping Klipper Service" "sudo systemctl stop klipper"
        else
            log_info "Klipper service not running, skipping stop."
        fi
    else
        log_warn "Klipper service not found. Attempting to stop manually..."
        pkill -f "klippy" 2>/dev/null || true
    fi
    
    # B. Swap Links
    log_info "Swapping Symlinks..."
    rm -rf "$HOME/klipper"
    ln -s "$repo" "$HOME/klipper"
    
    rm -rf "$HOME/klippy-env"
    ln -s "$env" "$HOME/klippy-env"
    
    # C. Start Service (only if service exists)
    if systemctl list-unit-files klipper.service &>/dev/null; then
        exec_silent "Restarting Klipper ($name)" "sudo systemctl start klipper"
        
        # D. Verification
        if systemctl is-active --quiet klipper; then
            log_success "Switch to $name SUCCESSFUL."
        else
            log_error "Service failed to start. Check logs."
        fi
    else
        log_warn "No systemd service found. Manual start required:"
        echo "  -> cd ~/klipper && ./scripts/klipper.sh start"
    fi
    
    read -p "  Press Enter..."
}

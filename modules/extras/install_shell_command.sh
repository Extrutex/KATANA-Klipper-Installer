#!/bin/bash

function install_shell_command() {
    log_info "Installing G-Code Shell Command Extension..."
    
    local source_file="$HOME/klipper/klippy/extras/gcode_shell_command.py"
    local bundled_file="$MODULES_DIR/extras/resources/gcode_shell_command.py"
    
    if [ ! -f "$source_file" ]; then
        if [ -f "$bundled_file" ]; then
            log_info "Installing bundled extension..."
            cp "$bundled_file" "$source_file"
            log_success "Extension installed from KATANA resources."
        else
            log_error "Bundled file not found: $bundled_file"
            return
        fi
    else
        log_info "Extension already exists. Skipping."
    fi
    
    # Restart Klipper to load
    log_info "Restarting Klipper..."
    sudo systemctl restart klipper
    
    read -p "  Press Enter..."
}

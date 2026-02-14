#!/bin/bash
# ==============================================================================
# KATANA MODULE: TIMELAPSE
# Moonraker Timelapse Setup
# ==============================================================================

function run_timelapse_menu() {
    while true; do
        draw_header "KATANA TIMELAPSE"
        echo ""
        echo "  [1] Install Timelapse"
        echo "  [2] Configure Timelapse"
        echo "  [3] View Timelapse Files"
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " cmd
        
        case $cmd in
            1) install_timelapse ;;
            2) configure_timelapse ;;
            3) view_timelapse_files ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function install_timelapse() {
    draw_header "INSTALL TIMELAPSE"
    echo ""
    
    # Check if Moonraker is installed
    if [ ! -d "$HOME/moonraker" ]; then
        log_error "Moonraker not installed. Install it first."
        read -p "  Press Enter..."
        return
    fi
    
    log_info "Installing Moonraker Timelapse..."
    
    # Clone timelapse extension
    local timelapse_dir="$HOME/moonraker/moonraker_timelapse"
    
    if [ -d "$timelapse_dir" ]; then
        log_info "Timelapse already installed. Pulling updates..."
        cd "$timelapse_dir" && git pull
    else
        cd "$HOME/moonraker"
        git clone https://github.com/mainsailcreations/moonraker-timelapse.git
    fi
    
    # Create config
    local conf_file="$HOME/printer_data/config/moonraker.conf"
    
    if ! grep -q "\[timelapse\]" "$conf_file" 2>/dev/null; then
        echo "" >> "$conf_file"
        echo "[timelapse]" >> "$conf_file"
        echo "enabled: True" >> "$conf_file"
        echo "directory: ~/timelapse" >> "$conf_file"
    fi
    
    # Create timelapse directory
    mkdir -p "$HOME/timelapse"
    
    log_success "Timelapse installed!"
    echo "  Config: $conf_file"
    echo "  Files: $HOME/timelapse"
    
    read -p "  Press Enter..."
}

function configure_timelapse() {
    draw_header "CONFIGURE TIMELAPSE"
    echo ""
    
    local conf_file="$HOME/printer_data/config/moonraker.conf"
    
    if [ ! -f "$conf_file" ]; then
        log_error "Moonraker config not found."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Current settings:"
    echo ""
    
    # Show current timelapse config
    if grep -A 10 "\[timelapse\]" "$conf_file" 2>/dev/null; then
        :
    else
        echo "  [timelapse] section not found!"
    fi
    
    echo ""
    echo "  [1] Change output directory"
    echo "  [2] Enable/Disable"
    echo "  [3] Reset to defaults"
    echo "  [B] Back"
    echo ""
    read -p "  >> SELECT: " selection
    
    case $selection in
        1) 
            echo "  New directory path (e.g., ~/timelapse):"
            read -p "  >> " new_dir
            sed -i "s|directory:.*|directory: $new_dir|" "$conf_file"
            log_success "Directory updated!"
            ;;
        2)
            if grep -q "enabled: True" "$conf_file"; then
                sed -i "s/enabled: True/enabled: False/" "$conf_file"
                log_info "Timelapse disabled"
            else
                sed -i "s/enabled: False/enabled: True/" "$conf_file"
                log_info "Timelapse enabled"
            fi
            ;;
        3)
            sed -i '/\[timelapse\]/,/^$/d' "$conf_file"
            echo "[timelapse]" >> "$conf_file"
            echo "enabled: True" >> "$conf_file"
            echo "directory: ~/timelapse" >> "$conf_file"
            log_success "Reset to defaults"
            ;;
    esac
    
    # Restart Moonraker
    sudo systemctl restart moonraker
    log_info "Moonraker restarted."
    
    read -p "  Press Enter..."
}

function view_timelapse_files() {
    draw_header "TIMELAPSE FILES"
    echo ""
    
    local timelapse_dir="$HOME/timelapse"
    
    if [ ! -d "$timelapse_dir" ]; then
        log_error "Timelapse directory not found."
        read -p "  Press Enter..."
        return
    fi
    
    local files=($(ls -1t "$timelapse_dir"/*.mp4 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        log_info "No timelapse files found."
    else
        echo "  Found ${#files[@]} timelapse(s):"
        echo ""
        
        local i=1
        for file in "${files[@]}"; do
            local size=$(du -h "$file" | cut -f1)
            local name=$(basename "$file")
            echo "  [$i] $name ($size)"
            ((i++))
        done
        
        echo ""
        echo "  To view, use: http://<pi-ip>/timelapse/"
    fi
    
    read -p "  Press Enter..."
}

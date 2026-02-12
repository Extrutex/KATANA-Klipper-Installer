#!/bin/bash

KATANA_FLOW_CFG_DIR="$CONFIGS_DIR/katana_flow"

function do_extras_menu() {
    while true; do
        draw_header "KATANA EXTRA MODULES"
        echo "  1) Install KATANA-FLOW (Smart Park/Purge)"
        echo "  2) Install Crowsnest (Webcam)"
        echo "  3) Install ShakeTune (Input Shaper)"
        echo "  4) Install KlipperScreen (Touch UI)"
        echo "  5) Install G-Code Shell Command"
        echo "  B) Back"
        read -p "  >> " ch
        
        case $ch in
            1) install_katana_flow ;;
            2) 
                if [ -f "$MODULES_DIR/extras/install_crowsnest.sh" ]; then
                    source "$MODULES_DIR/extras/install_crowsnest.sh"
                    install_crowsnest
                fi
                ;;
            3)
                if [ -f "$MODULES_DIR/extras/install_shaketune.sh" ]; then
                    source "$MODULES_DIR/extras/install_shaketune.sh"
                    install_shaketune
                fi
                ;;
            4)
                if [ -f "$MODULES_DIR/extras/install_klipperscreen.sh" ]; then
                    source "$MODULES_DIR/extras/install_klipperscreen.sh"
                    install_klipperscreen
                fi
                ;;
            5)
                if [ -f "$MODULES_DIR/extras/install_shell_command.sh" ]; then
                    source "$MODULES_DIR/extras/install_shell_command.sh"
                    install_shell_command
                fi
                ;;
            [bB]) return ;;
        esac
    done
}

function install_katana_flow() {
    draw_header "KATANA-FLOW INSTALLER"

    local dest_dir="$HOME/printer_data/config/katana_flow"
    mkdir -p "$dest_dir"

    # Copy files
    cp "$KATANA_FLOW_CFG_DIR/smart_park.cfg" "$dest_dir/"
    cp "$KATANA_FLOW_CFG_DIR/adaptive_purge.cfg" "$dest_dir/"
    
    log_success "Macros copied to $dest_dir"
    log_info "Please add '[include katana_flow/*.cfg]' to your printer.cfg"
    
    # Optional: Automate 'include' insertion
    if [ -f "$HOME/printer_data/config/printer.cfg" ]; then
        if ! grep -q "katana_flow" "$HOME/printer_data/config/printer.cfg"; then
            echo "" >> "$HOME/printer_data/config/printer.cfg"
            echo "[include katana_flow/*.cfg]" >> "$HOME/printer_data/config/printer.cfg"
            log_success "Added include line to printer.cfg"
        fi
    fi
    
    read -p "  Press Enter..."
}

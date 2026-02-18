#!/bin/bash
# modules/extras/install_katana_flow.sh
# Legacy entry point — redirects to katana_flow.sh

KATANA_FLOW_CFG_DIR="$CONFIGS_DIR/katana_flow"

function do_extras_menu() {
    while true; do
        draw_header "KATANA EXTRA MODULES"
        echo "  1) Install KATANA-FLOW (Print Lifecycle)"
        echo "  2) Install Crowsnest (Webcam)"
        echo "  3) Install ShakeTune (Input Shaper)"
        echo "  4) Install KlipperScreen (Touch UI)"
        echo "  5) Install G-Code Shell Command"
        echo "  B) Back"
        read -p "  >> " ch
        
        case $ch in
            1) 
                if [ -f "$MODULES_DIR/extras/katana_flow.sh" ]; then
                    source "$MODULES_DIR/extras/katana_flow.sh"
                    do_install_flow
                fi
                ;;
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

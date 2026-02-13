#!/bin/bash
# ==============================================================================
# KATANA MODULE: Hardware Menu Dispatcher
# Handles sub-menu for advanced hardware extensions
# ==============================================================================

function run_hardware_menu() {
    while true; do
        draw_header "HARDWARE EXTENSIONS"
        echo "  Advanced modules for specialized hardware."
        echo ""
        echo "  1) Happy Hare (MMU V1/V2/ERCF)"
        echo "  2) Smart Probe (Beacon/Cartographer)"
        echo "  B) Back to Main Menu"
        
        read -p "  >> SELECT OPTION: " ch
        case $ch in
            1) install_happy_hare ;;
            2) install_smart_probe ;;
            [bB]) return ;;
            *) log_error "Invalid Selection." ;;
        esac
    done
}

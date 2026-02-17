#!/bin/bash
# ==============================================================================
# KATANA AUTO-RESTART SERVICES
# ==============================================================================

function run_service_manager_menu() {
    while true; do
        draw_header "SERVICE AUTO-RESTART MANAGER"
        
        echo "  [1] Enable Auto-Restart All Services"
        echo "  [2] Enable Auto-Restart Klipper Only"
        echo "  [3] Enable Auto-Restart Moonraker Only"
        echo "  [4] Disable Auto-Restart"
        echo "  [5] View Service Health"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> " ch
        
        case $ch in
            1) enable_all_auto_restart ;;
            2) enable_klipper_auto_restart ;;
            3) enable_moonraker_auto_restart ;;
            4) disable_auto_restart ;;
            5) view_service_health ;;
            b|B) return ;;
        esac
    done
}

function enable_all_auto_restart() {
    log_info "Enabling auto-restart for all Klipper services..."
    
    enable_klipper_auto_restart
    enable_moonraker_auto_restart
    
    # Also restart webcam/crowsnest if installed
    if [ -d "$HOME/crowsnest" ]; then
        setup_service_restart "crowsnest"
    fi
    
    # KlipperScreen if installed
    if [ -d "$HOME/KlipperScreen" ]; then
        setup_service_restart "KlipperScreen"
    fi
    
    draw_success "Auto-restart enabled for all services!"
    read -p "  Press Enter..."
}

function enable_klipper_auto_restart() {
    log_info "Configuring Klipper auto-restart..."
    setup_service_restart "klipper"
    log_success "Klipper auto-restart enabled."
}

function enable_moonraker_auto_restart() {
    log_info "Configuring Moonraker auto-restart..."
    setup_service_restart "moonraker"
    log_success "Moonraker auto-restart enabled."
}

function setup_service_restart() {
    local service="$1"
    
    # Create override directory
    sudo mkdir -p /etc/systemd/system/${service}.service.d
    
    # Create override.conf
    sudo tee /etc/systemd/system/${service}.service.d/override.conf > /dev/null <<EOF
[Service]
# Auto-restart configuration
Restart=on-failure
RestartSec=10
# Watchdog (if supported)
WatchdogSec=60
# Keep trying even if it fails repeatedly
StartLimitInterval=0
EOF

    # Reload systemd
    sudo systemctl daemon-reload
    sudo systemctl restart $service
    
    log_info "Service $service configured with auto-restart."
}

function disable_auto_restart() {
    log_info "Disabling auto-restart for all services..."
    
    for service in klipper moonraker crowsnest KlipperScreen; do
        if [ -d "/etc/systemd/system/${service}.service.d" ]; then
            sudo rm -rf /etc/systemd/system/${service}.service.d
            log_info "Removed override for $service"
        fi
    done
    
    sudo systemctl daemon-reload
    
    draw_success "Auto-restart disabled for all services."
    read -p "  Press Enter..."
}

function view_service_health() {
    draw_header "SERVICE HEALTH STATUS"
    
    # Klipper
    local klipper_status=$(systemctl is-active klipper 2>/dev/null || echo "inactive")
    if [ "$klipper_status" = "active" ]; then
        box_row_left "${C_GREEN}●${NC} Klipper       : ${C_GREEN}ACTIVE${NC}"
    else
        box_row_left "${C_RED}●${NC} Klipper       : ${C_YELLOW}$klipper_status${NC}"
    fi
    
    # Moonraker
    local moonraker_status=$(systemctl is-active moonraker 2>/dev/null || echo "inactive")
    if [ "$moonraker_status" = "active" ]; then
        box_row_left "${C_GREEN}●${NC} Moonraker     : ${C_GREEN}ACTIVE${NC}"
    else
        box_row_left "${C_RED}●${NC} Moonraker     : ${C_YELLOW}$moonraker_status${NC}"
    fi
    
    # Crowsnest
    local crowsnest_status=$(systemctl is-active crowsnest 2>/dev/null || echo "inactive")
    if [ "$crowsnest_status" = "active" ]; then
        box_row_left "${C_GREEN}●${NC} Crowsnest     : ${C_GREEN}ACTIVE${NC}"
    else
        box_row_left "${C_GREY}○${NC} Crowsnest     : ${C_GREY}$crowsnest_status${NC}"
    fi
    
    # KlipperScreen
    local klipperscreen_status=$(systemctl is-active KlipperScreen 2>/dev/null || echo "inactive")
    if [ "$klipperscreen_status" = "active" ]; then
        box_row_left "${C_GREEN}●${NC} KlipperScreen : ${C_GREEN}ACTIVE${NC}"
    else
        box_row_left "${C_GREY}○${NC} KlipperScreen : ${C_GREY}$klipperscreen_status${NC}"
    fi
    
    echo ""
    
    # Auto-restart status
    box_row_left "${C_WHITE}Auto-Restart Status:${NC}"
    
    if [ -d /etc/systemd/system/klipper.service.d ]; then
        box_row_left "${C_GREEN}●${NC} Klipper  : ENABLED"
    else
        box_row_left "${C_GREY}○${NC} Klipper  : DISABLED"
    fi
    
    if [ -d /etc/systemd/system/moonraker.service.d ]; then
        box_row_left "${C_GREEN}●${NC} Moonraker: ENABLED"
    else
        box_row_left "${C_GREY}○${NC} Moonraker: DISABLED"
    fi
    
    echo ""
    read -p "  Press Enter..."
}

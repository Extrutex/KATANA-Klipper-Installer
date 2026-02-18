#!/bin/bash
# modules/system/instance_manager.sh
# KATANA MODULE: INSTANCE MANAGER
# Manages multiple Klipper/Moonraker instances.

function run_instance_manager() {
    while true; do
        draw_header "📟 INSTANCE MANAGER"
        
        # List Existing Instances
        echo -e "${C_NEON}Active Instances:${NC}"
        list_instances
        echo ""
        
        echo "  [1] Add new instance"
        echo "  [2] Remove instance"
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) add_new_instance ;;
            2) remove_instance ;;
            [bB]) return ;;
            *) log_error "Invalid selection" ;;
        esac
    done
}

function list_instances() {
    # Find all printer_data directories that actually contain a config folder
    local instances=()
    for d in $HOME/printer_data*; do
        if [ -d "$d/config" ]; then
            instances+=("$d")
        fi
    done

    if [ ${#instances[@]} -eq 0 ]; then
        echo "    No instances found."
        return
    fi
    
    printf "    %-20s | %-10s | %-10s\n" "DIRECTORY" "PORT" "STATUS"
    echo "    --------------------------------------------------------"
    
    for inst in "${instances[@]}"; do
        local name=$(basename "$inst")
        # Find port from moonraker.conf
        local port=$(grep "^port =" "$inst/config/moonraker.conf" 2>/dev/null | awk '{print $3}')
        [ -z "$port" ] && port="??"
        
        # Match service names by naming convention
        local svc_name=""
        if [ "$name" == "printer_data" ]; then
            svc_name="klipper"
        else
            svc_name="klipper-${name#printer_data_}"
        fi

        local status_color=$C_RED
        local status_text="OFF"
        if systemctl is-active --quiet "$svc_name" 2>/dev/null; then
            status_color=$C_GREEN
            status_text="RUNNING"
        fi
        
        printf "    %-20s | %-10s | %b%-10s${NC}\n" "$name" "$port" "$status_color" "$status_text"
    done
}

function add_new_instance() {
    draw_header "ADD INSTANCE"
    
    # 1. Find next free number
    local next_num=2
    while [ -d "$HOME/printer_data_$next_num" ]; do
        ((next_num++))
    done
    
    # 2. Find next free port
    local next_port=7125
    local ports_in_use=$(grep "^port =" $HOME/printer_data*/config/moonraker.conf 2>/dev/null | awk '{print $3}')
    while true; do
        if ! echo "$ports_in_use" | grep -qx "$next_port"; then
            break
        fi
        ((next_port++))
    done

    echo "  New instance proposal:"
    echo "  - Directory: ~/printer_data_$next_num"
    echo "  - Port:      $next_port"
    echo "  - Service:   klipper-$next_num / moonraker-$next_num"
    echo ""
    read -p "  Create? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi

    local data_dir="$HOME/printer_data_$next_num"
    local k_svc="klipper-$next_num"
    local m_svc="moonraker-$next_num"

    # Call refactored installers
    if [ -f "$MODULES_DIR/engine/install_klipper.sh" ]; then
        source "$MODULES_DIR/engine/install_klipper.sh"
        
        log_info "Creating instance $next_num..."
        do_install_klipper "Standard" "$data_dir" "$k_svc"
        do_install_moonraker "$data_dir" "$m_svc" "$next_port"
        
        draw_success "INSTANCE $next_num INSTALLED!"
        echo "  Accessible at: http://$(hostname -I | awk '{print $1}'):$next_port"
    else
        log_error "Installer module not found."
    fi
    
    read -p "  Press Enter..."
}

function remove_instance() {
    draw_header "REMOVE INSTANCE"
    
    local instances=$(ls -d "$HOME"/printer_data* 2>/dev/null)
    if [ -z "$instances" ]; then
        log_error "No instances found to remove."
        read -p "  Press Enter..."
        return
    fi

    echo "  Select instance to DELETE:"
    local inst_arr=($instances)
    for i in "${!inst_arr[@]}"; do
        echo "    [$((i+1))] $(basename "${inst_arr[$i]}")"
    done
    echo ""
    read -p "  Select [1-${#inst_arr[@]}] or [B]ack: " choice
    if [[ "$choice" =~ ^[bB]$ ]]; then return; fi
    
    local idx=$((choice - 1))
    local target="${inst_arr[$idx]}"
    local name=$(basename "$target")
    
    if [ "$name" == "printer_data" ]; then
        log_warn "This is the base instance. Are you sure?"
    fi

    echo -e "${C_RED}!!! WARNING: This will delete all configs and service files for $name !!!${NC}"
    read -p "  Confirm? Type 'DELETE': " confirm
    if [ "$confirm" != "DELETE" ]; then return; fi

    log_info "Removing services..."
    local k_svc="klipper"; local m_svc="moonraker"
    if [ "$name" != "printer_data" ]; then
        local num="${name#printer_data_}"
        k_svc="klipper-$num"
        m_svc="moonraker-$num"
    fi

    sudo systemctl stop "$k_svc" "$m_svc" 2>/dev/null
    sudo systemctl disable "$k_svc" "$m_svc" 2>/dev/null
    sudo rm "/etc/systemd/system/$k_svc.service" "/etc/systemd/system/$m_svc.service" 2>/dev/null
    sudo systemctl daemon-reload

    log_info "Deleting data directory..."
    rm -rf "$target"
    
    draw_success "$name removed completely."
    read -p "  Press Enter..."
}

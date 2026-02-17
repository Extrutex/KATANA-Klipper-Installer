#!/bin/bash
# modules/system/instance_manager.sh
# KATANA MODULE: INSTANCE MANAGER
# Manages multiple Klipper/Moonraker instances.

function run_instance_manager() {
    while true; do
        draw_header "📟 INSTANCE MANAGER"
        
        # List Existing Instances
        echo -e "${C_NEON}Aktive Instanzen:${NC}"
        list_instances
        echo ""
        
        echo "  [1] Neue Instanz hinzufügen"
        echo "  [2] Instanz entfernen"
        echo "  [B] Zurück"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) add_new_instance ;;
            2) remove_instance ;;
            [bB]) return ;;
            *) log_error "Ungültige Auswahl" ;;
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
        echo "    Keine Instanzen gefunden."
        return
    fi
    
    printf "    %-20s | %-10s | %-10s\n" "VERZEICHNIS" "PORT" "STATUS"
    echo "    --------------------------------------------------------"
    
    for inst in "${instances[@]}"; do
        local name=$(basename "$inst")
        # Find port from moonraker.conf
        local port=$(grep "^port =" "$inst/config/moonraker.conf" 2>/dev/null | awk '{print $3}')
        [ -z "$port" ] && port="??"
        
        # Heuristic for service names
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
    draw_header "INSTANZ HINZUFÜGEN"
    
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

    echo "  Vorschlag für neue Instanz:"
    echo "  - Ordner: ~/printer_data_$next_num"
    echo "  - Port:   $next_port"
    echo "  - Service: klipper-$next_num / moonraker-$next_num"
    echo ""
    read -p "  Erstellen? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi

    local data_dir="$HOME/printer_data_$next_num"
    local k_svc="klipper-$next_num"
    local m_svc="moonraker-$next_num"

    # Call refactored installers
    if [ -f "$MODULES_DIR/engine/install_klipper.sh" ]; then
        source "$MODULES_DIR/engine/install_klipper.sh"
        
        log_info "Erzeuge Instanz $next_num..."
        do_install_klipper "Standard" "$data_dir" "$k_svc"
        do_install_moonraker "$data_dir" "$m_svc" "$next_port"
        
        draw_success "INSTANZ $next_num INSTALLIERT!"
        echo "  Erreichbar unter: http://$(hostname -I | awk '{print $1}'):$next_port"
    else
        log_error "Installer Modul nicht gefunden."
    fi
    
    read -p "  Press Enter..."
}

function remove_instance() {
    draw_header "INSTANZ ENTFERNEN"
    
    local instances=$(ls -d $HOME/printer_data* 2>/dev/null)
    if [ -z "$instances" ]; then
        log_error "Keine Instanzen zum Entfernen gefunden."
        read -p "  Press Enter..."
        return
    fi

    echo "  Wähle Instanz zum LÖSCHEN:"
    local inst_arr=($instances)
    for i in "${!inst_arr[@]}"; do
        echo "    [$((i+1))] $(basename "${inst_arr[$i]}")"
    done
    echo ""
    read -p "  Auswahl [1-${#inst_arr[@]}] oder [B]ack: " choice
    if [[ "$choice" =~ ^[bB]$ ]]; then return; fi
    
    local idx=$((choice - 1))
    local target="${inst_arr[$idx]}"
    local name=$(basename "$target")
    
    if [ "$name" == "printer_data" ]; then
        log_warn "Das ist die Basis-Instanz. Wirklich löschen?"
    fi

    echo -e "${C_RED}!!! ACHTUNG: Das löscht alle Configs und Service-Files für $name !!!${NC}"
    read -p "  Sicher? Type 'DELETE': " confirm
    if [ "$confirm" != "DELETE" ]; then return; fi

    log_info "Entferne Services..."
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

    log_info "Lösche Daten-Verzeichnis..."
    rm -rf "$target"
    
    draw_success "$name wurde vollständig entfernt."
    read -p "  Press Enter..."
}

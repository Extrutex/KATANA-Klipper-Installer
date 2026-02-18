#!/bin/bash
# modules/hardware/can_manager.sh
# KATANA MODULE: CAN-BUS MANAGER
# Handles network config, Katapult bootloader and UUID scanning.

function run_can_manager() {
    while true; do
        draw_header "🚌 CAN-BUS MANAGER"
        echo ""
        echo "  [1] CAN-Netzwerk konfigurieren (can0)"
        echo "  [2] Katapult Bootloader installieren (DFU)"
        echo "  [3] CAN-Geräte scannen (UUIDs finden)"
        echo "  [4] Flash via Katapult (Bestehende UUID)"
        echo ""
        echo "  [B] Zurück"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) setup_can_network ;;
            2) install_katapult_wizard ;;
            3) scan_can_devices ;;
            4) flash_via_katapult_wizard ;;
            [bB]) return ;;
            *) log_error "Ungültige Auswahl" ;;
        esac
    done
}

function setup_can_network() {
    draw_header "CAN-NETZWERK SETUP"
    
    local bitrate=1000000
    local txqueuelen=1024
    
    echo "  Vorkonfiguration für can0:"
    echo "  - Bitrate: $bitrate"
    echo "  - TX Queue Length: $txqueuelen"
    echo ""
    read -p "  Konfiguration schreiben? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi

    log_info "Erzeuge /etc/network/interfaces.d/can0..."
    sudo tee /etc/network/interfaces.d/can0 > /dev/null <<EOF
allow-hotplug can0
iface can0 can static
    bitrate $bitrate
    up ip link set \$IFACE txqueuelen $txqueuelen
EOF

    log_info "Aktiviere Netzwerk..."
    sudo ip link set can0 up type can bitrate "$bitrate" 2>/dev/null || sudo ifup can0 2>/dev/null
    
    if ip link show can0 | grep -q "UP"; then
        draw_success "CAN0 IST AKTIV!"
    else
        log_warn "Konnte CAN0 nicht direkt aktivieren. Evtl. ist kein CAN-Adapter verbunden."
    fi
    sleep 2
}

function scan_can_devices() {
    draw_header "CAN-GERÄTE SCANNER"
    
    # 1. Check Python Dependencies
    if ! python3 -c "import serial, can" &>/dev/null; then
        log_info "Installiere Python-Abhängigkeiten (serial, can)..."
        sudo apt-get update && sudo apt-get install -y python3-serial python3-can
    fi

    # 2. Check Katapult Repo
    if [ ! -d "$HOME/katapult" ]; then
        log_info "Katapult Repo benötigt für Scanner. Klone..."
        git clone https://github.com/Arksine/katapult "$HOME/katapult"
    fi

    log_info "Scanne Bus (can0)..."
    echo ""
    
    local output=$(python3 "$HOME/katapult/scripts/flashtool.py" -i can0 -q 2>&1)
    
    if echo "$output" | grep -q "Detected UUID"; then
        echo -e "${C_GREEN}Gefundene Geräte:${NC}"
        echo "$output" | grep "Detected UUID"
    else
        log_warn "Keine CAN-Geräte im Katapult-Modus gefunden."
        echo "  Stelle sicher, dass der Bootloader im Flash-Modus ist."
    fi
    
    echo ""
    read -p "  Press Enter..."
}

function install_katapult_wizard() {
    local board=""
    
    while true; do
        draw_header "⚡ KATAPULT INSTALL WIZARD"
        echo -e "${C_PURPLE}Select your Board (DFU Flash):${NC}"
        echo ""
        echo "  ${C_NEON}[1]${NC}  BTT EBB36/42 v1.1/v1.2 (STM32G0B1)"
        echo "  ${C_NEON}[2]${NC}  BTT Octopus Pro (STM32F446)"
        echo "  ${C_NEON}[3]${NC}  BTT Octopus Pro (STM32F429)"
        echo "  ${C_NEON}[4]${NC}  BTT SB2209 (RP2040)"
        echo "  ${C_NEON}[5]${NC}  MKS SKIPR (STM32F407)"
        echo "  ${C_NEON}[6]${NC}  Fysetc Cheetah v2.0 (STM32F072)"
        echo ""
        echo "  [B] Zurück"
        echo ""
        read -p "  >> Auswahl: " choice
        
        case $choice in
            1) board="ebb42"; break ;;
            2) board="octopus446"; break ;;
            3) board="octopus429"; break ;;
            4) board="sb2209_rp2040"; break ;;
            5) board="mksskipr"; break ;;
            6) board="cheetah"; break ;;
            [bB]) return ;;
        esac
    done

    # Step 2: Build Katapult
    local katapult_dir="$HOME/katapult"
    if [ ! -d "$katapult_dir" ]; then
        log_info "Klone Katapult..."
        git clone https://github.com/Arksine/katapult "$katapult_dir"
    fi
    
    cd "$katapult_dir" || { log_error "Katapult directory not found"; return 1; }
    make clean &>/dev/null
    
    log_info "Generiere Konfiguration..."
    case $board in
        ebb42)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32g0b1"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_STM32_CANBUS_PB0_PB1=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        octopus446)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f446"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        octopus429)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f429"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        sb2209_rp2040)
            cat > .config <<'EOF'
CONFIG_MACH_RP2040=y
CONFIG_MCU="rp2040"
CONFIG_BOARD_DIRECTORY="rp2040"
CONFIG_RP2040_CANBUS_GPIO28_GPIO29=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        mksskipr)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f407"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_STM32_CANBUS_PD0_PD1=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        cheetah)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f072"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
    esac
    
    make olddefconfig &>/dev/null
    exec_silent "Baue Katapult" "make -j$(nproc)"
    
    if [ ! -f "out/katapult.bin" ] && [ ! -f "out/katapult.uf2" ]; then
        log_error "Build fehlgeschlagen!"
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    echo -e "${C_YELLOW}!!! MCU IN DFU MODUS SETZEN !!!${NC}"
    echo "  (Boot-Button gedrückt halten + Reset)"
    read -p "  Enter drücken wenn bereit..."
    
    log_info "Flashe Bootloader..."
    if [[ "$board" == "sb2209_rp2040" ]]; then
        # RP2040 flash via mass storage instructions or direct tool head flash
        log_warn "RP2040 Flash via Mass Storage Copy empfohlen."
        echo "  Datei: $katapult_dir/out/katapult.uf2"
    else
        sudo dfu-util -a 0 -d 0483:df11 -D out/katapult.bin -s 0x08000000:leave
    fi
    
    [ $? -eq 0 ] && draw_success "Katapult erfolgreich installiert!" || log_error "Flash fehlgeschlagen!"
    read -p "  Press Enter..."
}

function flash_via_katapult_wizard() {
    draw_header "FLASH VIA KATAPULT (CAN)"
    
    local klipper_dir="$HOME/klipper"
    local firmware="$klipper_dir/out/klipper.bin"
    
    if [ ! -f "$firmware" ]; then
        log_error "Keine Firmware gefunden! Bitte erst unter 'The Forge -> Manual Build' bauen."
        read -p "  Press Enter..."
        return
    fi
    
    # 1. Scan for devices
    log_info "Suche nach Geräten im Katapult-Modus..."
    local scan_output=$(python3 "$HOME/katapult/scripts/flashtool.py" -i can0 -q 2>&1)
    local uuids=($(echo "$scan_output" | grep "Detected UUID" | awk '{print $3}'))
    
    if [ ${#uuids[@]} -eq 0 ]; then
        log_warn "Keine CAN-Geräte im Flash-Modus gefunden."
        read -p "  Soll die UUID manuell eingegeben werden? [y/N]: " yn
        if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
        read -p "  UUID: " selected_uuid
    elif [ ${#uuids[@]} -eq 1 ]; then
        selected_uuid="${uuids[0]}"
        log_success "Gefunden: $selected_uuid"
    else
        echo "  Mehrere Geräte gefunden:"
        for i in "${!uuids[@]}"; do
            echo "    [$((i+1))] ${uuids[$i]}"
        done
        read -p "  Auswahl [1-${#uuids[@]}]: " choice
        selected_uuid="${uuids[$((choice-1))]}"
    fi
    
    if [ -z "$selected_uuid" ]; then return; fi
    
    echo ""
    log_info "Flashe $firmware auf $selected_uuid..."
    python3 "$HOME/katapult/scripts/flashtool.py" -i can0 -u "$selected_uuid" -f "$firmware"
    
    if [ $? -eq 0 ]; then
        draw_success "FLASH ERFOLGREICH!"
        echo ""
        echo -e "${C_CYAN}Gefundene UUID: $selected_uuid${NC}"
        echo ""
        read -p "  Soll diese UUID in eine printer.cfg eingetragen werden? [y/N]: " inject_yn
        if [[ "$inject_yn" =~ ^[yY]$ ]]; then
            # 2. Select target instance
            local instances=($(ls -d $HOME/printer_data* 2>/dev/null))
            if [ ${#instances[@]} -eq 1 ]; then
                inject_uuid_to_config "$selected_uuid" "${instances[0]}"
            else
                echo "  Wähle Ziel-Instanz:"
                for i in "${!instances[@]}"; do
                    echo "    [$((i+1))] $(basename "${instances[$i]}")"
                done
                read -p "  Auswahl [1-${#instances[@]}]: " inst_choice
                if [ -n "${instances[$((inst_choice-1))]}" ]; then
                    inject_uuid_to_config "$selected_uuid" "${instances[$((inst_choice-1))]}"
                fi
            fi
        fi
    else
        log_error "Flash fehlgeschlagen."
    fi
    
    read -p "  Press Enter..."
}

function inject_uuid_to_config() {
    local uuid="$1"
    local data_dir="${2:-$HOME/printer_data}"
    local config_file="$data_dir/config/printer.cfg"
    
    if [ ! -f "$config_file" ]; then
        log_error "printer.cfg nicht gefunden in $(basename $data_dir)!"
        return
    fi
    
    log_info "Aktualisiere $(basename $data_dir)/config/printer.cfg..."
    
    # Check if [mcu can0] exists
    if grep -q "\[mcu can0\]" "$config_file"; then
        # Replace existing uuid
        sudo sed -i "s/^canbus_uuid:.*/canbus_uuid: $uuid/" "$config_file"
    else
        # Append new section
        echo -e "\n[mcu can0]\ncanbus_uuid: $uuid" >> "$config_file"
    fi
    
    log_success "UUID eingenascht! Bitte Klipper neustarten."
}

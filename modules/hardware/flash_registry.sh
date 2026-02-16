#!/bin/bash

export TERM=xterm-256color

# --- THE FORGE: MCU FLASHING & DETECTION ---
source "$MODULES_DIR/system/mcu_builder.sh"

function run_flash_menu() {
    while true; do
        draw_header "⚒ THE FORGE - MCU MANAGER"
        
        echo "  [1] Detect MCUs (USB & CAN)"
        echo "  [2] Quick Build (Preconfigured Boards)"
        echo "  [3] Manual Build (make menuconfig)"
        echo "  [4] Flash Firmware"
        echo "  [5] Setup CAN-Bus Network"
        echo "  [6] Install Katapult Bootloader"
        echo "  [7] Flash via Katapult (CAN)"
        echo "  [8] HAL Board Profiles"
        echo ""
        echo "  ${C_GREEN}[Q]${NC}  Quick CAN Setup Wizard      <-- RECOMMENDED!"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) detect_mcus ;;
            2) run_quick_build_menu ;;
            3) manual_build ;;
            4) select_flash_method ;;
            5) setup_can_network ;;
            6) install_katapult ;;
            7) flash_via_katapult ;;
            8) run_hal_flasher ;;
            q|Q) run_quick_can_wizard ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function detect_mcus() {
    draw_header "DETECTING MCUs"
    
    log_info "Scanning USB Bus..."
    local usb_devs=$(ls /dev/serial/by-id/* 2>/dev/null)
    
    if [ -z "$usb_devs" ]; then
        echo "  [WARN] No USB Serial devices found."
    else
        echo "  [+] USB Devices Found:"
        echo "$usb_devs"
    fi
    
    echo ""
    log_info "Scanning CAN Bus..."
    
    if [ -f "$KATANA_ROOT/scripts/can_scanner.py" ]; then
        python3 "$KATANA_ROOT/scripts/can_scanner.py"
    else
        echo "  [!] Scanner script not found."
    fi
    
    read -p "  Press Enter..."
}

function manual_build() {
    draw_header "MANUAL BUILD"
    
    local klipper_dir="$HOME/klipper"
    if [ ! -d "$klipper_dir" ]; then
        draw_error "Klipper not found at $klipper_dir"
        read -p "  Press Enter..."
        return
    fi
    
    log_info "Starting Klipper Build System..."
    echo ""
    echo "  This will open make menuconfig for custom configuration."
    echo "  After saving config, the firmware will be compiled automatically."
    echo ""
    read -p "  Continue? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    cd "$klipper_dir"
    
    log_info "Running make menuconfig..."
    make menuconfig
    
    log_info "Building Firmware..."
    make -j$(nproc)
    
    if [ $? -eq 0 ]; then
        draw_success "Build Successful!"
        echo ""
        echo "  Firmware: $klipper_dir/out/klipper.bin"
        echo ""
    else
        draw_error "Build failed!"
    fi
    
    read -p "  Press Enter..."
}

function select_flash_method() {
    while true; do
        draw_header "FLASH METHOD"
        
        echo "  [1] USB/Serial (dfu-util)"
        echo "  [2] SD Card"
        echo "  [3] CAN-Bus (Katapult)"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> SELECT: " ch
        
        case $ch in
            1) flash_via_usb ;;
            2) flash_via_sdcard ;;
            3) flash_via_katapult ;;
            b|B) return ;;
        esac
    done
}

function flash_via_usb() {
    draw_header "FLASH VIA USB"
    
    local klipper_dir="$HOME/klipper"
    local firmware="$klipper_dir/out/klipper.bin"
    
    if [ ! -f "$firmware" ]; then
        draw_error "No firmware found! Build firmware first (Option 2 or 3)."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Detecting USB devices..."
    local usb_devs=$(ls /dev/serial/by-id/* 2>/dev/null)
    
    if [ -z "$usb_devs" ]; then
        draw_error "No USB devices found! Make sure MCU is connected via USB."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Available devices:"
    echo "$usb_devs"
    echo ""
    read -p "  Enter device path (e.g., /dev/serial/by-id/...): " device
    
    if [ -z "$device" ]; then
        log_error "No device specified."
        return
    fi
    
    echo ""
    log_info "Flashing firmware to $device..."
    
    cd "$klipper_dir"
    make flash FLASH_DEVICE="$device"
    
    if [ $? -eq 0 ]; then
        draw_success "Flash successful!"
    else
        draw_error "Flash failed!"
    fi
    
    read -p "  Press Enter..."
}

function flash_via_sdcard() {
    draw_header "FLASH VIA SD CARD"
    
    local klipper_dir="$HOME/klipper"
    local firmware="$klipper_dir/out/klipper.bin"
    
    if [ ! -f "$firmware" ]; then
        draw_error "No firmware found! Build firmware first (Option 2 or 3)."
        read -p "  Press Enter..."
        return
    fi
    
    draw_success "Build complete!"
    echo ""
    echo "  Firmware location: $firmware"
    echo ""
    echo "  Instructions:"
    echo "  1. Copy klipper.bin to your SD card"
    echo "  2. Rename the file to firmware.bin"
    echo "  3. Insert SD card into your MCU"
    echo "  4. Power on the MCU while holding the boot button"
    echo "     (or enter DFU mode)"
    echo ""
    echo "  Note: Some boards require specific DFU procedures."
    echo "        Check your board's documentation."
    echo ""
    
    read -p "  Press Enter..."
}

function setup_can_network() {
    draw_header "SETUP CAN-BUS NETWORK"
    
    echo "  Target Bitrate:"
    echo "  1) 1000000 (1M) - [RECOMMENDED]"
    echo "  2) 500000 (500k) - [Legacy]"
    echo ""
    echo "  [B] Back"
    read -p "  >> " br_sel
    
    if [[ "$br_sel" =~ ^[bB]$ ]]; then return; fi
    
    local bitrate="1000000"
    if [ "$br_sel" == "2" ]; then bitrate="500000"; fi
    
    local net_file="/etc/network/interfaces.d/can0"
    
    echo ""
    log_info "Creating $net_file with bitrate $bitrate..."
    
    sudo tee "$net_file" > /dev/null <<EOF
allow-hotplug can0
iface can0 can static
    bitrate $bitrate
    up ifconfig \$IFACE txqueuelen 128
EOF
    
    draw_success "Interface file created."
    
    log_info "Bringing up can0 interface..."
    sudo ip link set can0 up type can bitrate $bitrate 2>/dev/null || \
        sudo ifup can0 2>/dev/null
    
    echo ""
    ip -br link show can0
    echo ""
    draw_success "CAN-Bus network configured!"
    
    read -p "  Press Enter..."
}

function install_katapult() {
    draw_header "INSTALL KATAPULT BOOTLOADER"
    
    echo "  Katapult is a bootloader for Klipper MCUs."
    echo "  It enables firmware flashing via USB or CAN-Bus."
    echo ""
    echo "  Requirements:"
    echo "  - STM32F0xx, STM32F4xx, STM32H7xx, or RP2040 MCU"
    echo "  - USB connection to the MCU"
    echo ""
    read -p "  Continue? [y/N] " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local katapult_dir="$HOME/katapult"
    
    if [ ! -d "$katapult_dir" ]; then
        log_info "Cloning Katapult repository..."
        cd "$HOME"
        git clone https://github.com/Arksine/katapult
    fi
    
    cd "$katapult_dir"
    
    log_info "Running make menuconfig..."
    make menuconfig
    
    log_info "Building Katapult..."
    make -j$(nproc)
    
    if [ $? -eq 0 ]; then
        draw_success "Build complete!"
        echo ""
        echo "  Firmware: $katapult_dir/out/katapult.bin"
        echo ""
        echo "  Flash instructions:"
        echo "  1. Connect MCU via USB"
        echo "  2. Enter DFU mode (hold boot button + reset)"
        echo "  3. Run: make flash FLASH_DEVICE=/dev/ttyACM0"
        echo ""
        echo "  Or use STM32CubeProgrammer for initial flash."
    else
        draw_error "Build failed!"
    fi
    
    read -p "  Press Enter..."
}

function flash_via_katapult() {
    draw_header "FLASH VIA KATAPULT (CAN-BUS)"
    
    local klipper_dir="$HOME/klipper"
    local firmware="$klipper_dir/out/klipper.bin"
    
    if [ ! -f "$firmware" ]; then
        draw_error "No firmware found! Build firmware first (Option 2 or 3)."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Checking CAN-Bus connection..."
    
    if ! ip link show can0 > /dev/null 2>&1; then
        draw_error "CAN-Bus interface not found! Setup CAN network first (Option 5)."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Scanning for Katapult devices..."
    echo ""
    
    if [ -f "$HOME/katapult/scripts/flashtool.py" ]; then
        python3 "$HOME/katapult/scripts/flashtool.py" -q
    else
        echo "  [!] Katapult flashtool not found."
        echo "      Install Katapult first (Option 6)."
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    read -p "  Enter CAN UUID to flash: " uuid
    
    if [ -z "$uuid" ]; then
        log_error "No UUID specified."
        return
    fi
    
    log_info "Flashing firmware to CAN UUID: $uuid"
    
    cd "$klipper_dir"
    python3 "$HOME/katapult/scripts/flashtool.py" -u "$uuid" -f "$firmware"
    
    if [ $? -eq 0 ]; then
        draw_success "Flash successful!"
    else
        draw_error "Flash failed!"
    fi
    
    read -p "  Press Enter..."
}

# ============================================================
# QUICK CAN SETUP WIZARD
# ============================================================

function run_quick_can_wizard() {
    local board=""
    local can_pin=""
    local mcu_type=""
    
    while true; do
        draw_header "⚡ QUICK CAN SETUP WIZARD"
        
        echo -e "${C_PURPLE}Select your Board:${NC}"
        echo ""
        echo "  ${C_NEON}[1]${NC}  BTT EBB36/42 v1.1/v1.2 (STM32G0B1)  - Most Common"
        echo "  ${C_NEON}[2]${NC}  BTT Octopus Pro (STM32F446)"
        echo "  ${C_NEON}[3]${NC}  BTT Octopus Pro (STM32F429)"
        echo "  ${C_NEON}[4]${NC}  BTT SB2209 (RP2040)"
        echo "  ${C_NEON}[5]${NC}  MKS SKIPR (STM32F407)"
        echo "  ${C_NEON}[6]${NC}  Fysetc Cheetah v2.0 (STM32F072)"
        echo ""
        echo "  ${C_GREY}[B]${NC}  Back to Forge Menu"
        echo ""
        read -p "  >> CHOICE: " ch
        
        case $ch in
            1) board="ebb42"; mcu_type="stm32g0b1"; can_pin="PB0_PB1"; break ;;
            2) board="octopus446"; mcu_type="stm32f446"; can_pin="PA11_PA12"; break ;;
            3) board="octopus429"; mcu_type="stm32f429"; can_pin="PA11_PA12"; break ;;
            4) board="sb2209_rp2040"; mcu_type="rp2040"; can_pin="GPIO28_GPIO29"; break ;;
            5) board="mksskipr"; mcu_type="stm32f407"; can_pin="PD0_PD1"; break ;;
            6) board="cheetah"; mcu_type="stm32f072"; can_pin="PA11_PA12"; break ;;
            b|B) return ;;
        esac
    done
    
    clear
    draw_header "⚡ QUICK CAN SETUP - $board"
    
    echo -e "${C_GREEN}Step 1/4: Configure CAN-Bus Network${NC}"
    echo ""
    
    local net_file="/etc/network/interfaces.d/can0"
    sudo tee "$net_file" > /dev/null <<'EOF'
allow-hotplug can0
iface can0 can static
    bitrate 1000000
    up ifconfig $IFACE txqueuelen 128
EOF
    
    sudo ip link set can0 up type can bitrate 1000000 2>/dev/null || sudo ifup can0 2>/dev/null
    
    if ip -br link show can0 &>/dev/null; then
        echo -e "  ${C_GREEN}✓${NC} CAN-Netzwerk konfiguriert"
    else
        echo -e "  ${C_YELLOW}!${NC} CAN-Interface konnte nicht aktiviert werden"
    fi
    
    echo ""
    echo -e "${C_GREEN}Step 2/4: Install Katapult Bootloader${NC}"
    echo ""
    
    local katapult_dir="$HOME/katapult"
    if [ ! -d "$katapult_dir" ]; then
        echo "  Klonen von Katapult..."
        cd "$HOME"
        git clone https://github.com/Arksine/katapult
    fi
    
    cd "$katapult_dir"
    make clean &>/dev/null
    
    case $board in
        ebb42)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32g0b1"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x20000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=1000000
CONFIG_CANBUS_PB0_PB1=y
EOF
            ;;
        octopus446)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f446"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x80000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=1000000
CONFIG_STM32_CANBUS_PA11_PA12=y
EOF
            ;;
        octopus429)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f429"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x80000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=1000000
CONFIG_STM32_CANBUS_PA11_PA12=y
EOF
            ;;
        sb2209_rp2040)
            cat > .config <<'EOF'
CONFIG_MACH_RP2040=y
CONFIG_MCU="rp2040"
CONFIG_BOARD_DIRECTORY="rp2040"
CONFIG_FLASH_SIZE=0x200000
CONFIG_RP2040_SELECT=y
CONFIG_CANBUS_FREQUENCY=1000000
CONFIG_CANBUS_GPIO_TX=28
CONFIG_CANBUS_GPIO_RX=29
EOF
            ;;
        mksskipr)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f407"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x80000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=1000000
CONFIG_STM32_CANBUS_PD0_PD1=y
EOF
            ;;
        cheetah)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f072"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x20000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=1000000
CONFIG_STM32_CANBUS_PA11_PA12=y
EOF
            ;;
    esac
    
    make olddefconfig &>/dev/null
    make -j$(nproc) &>/dev/null
    
    if [ -f "$katapult_dir/out/katapult.bin" ]; then
        echo -e "  ${C_GREEN}✓${NC} Katapult gebaut"
    else
        echo -e "  ${C_RED}✗${NC} Katapult Build fehlgeschlagen"
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    echo -e "${C_YELLOW}!!! BITTE MCU IN DFU MODUS SETZEN !!!${NC}"
    echo ""
    echo "  Halte den Boot-Button gedrückt und verbinde USB"
    echo ""
    read -p "  Enter drücken wenn bereit..."
    
    echo ""
    echo "  Flashe Katapult..."
    make flash FLASH_DEVICE=0483:df11 &>/dev/null || echo -e "  ${C_YELLOW}!${NC} Bitte manuell flashen"
    
    echo ""
    echo -e "${C_GREEN}Step 3/4: Build Klipper Firmware${NC}"
    echo ""
    
    local klipper_dir="$HOME/klipper"
    cd "$klipper_dir"
    make clean &>/dev/null
    
    case $board in
        ebb42)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32g0b1"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8002000
CONFIG_STM32_CANBUS_PB0_PB1=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        octopus446)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f446"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8002000
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        octopus429)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f429"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8002000
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        sb2209_rp2040)
            cat > .config <<'EOF'
CONFIG_MACH_RP2040=y
CONFIG_MCU="rp2040"
CONFIG_BOARD_DIRECTORY="rp2040"
CONFIG_RP2040_FLASH_START_2000=y
CONFIG_RP2040_CANBUS_GPIO28_GPIO29=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        mksskipr)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f407"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x800c000
CONFIG_STM32_CANBUS_PD0_PD1=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
        cheetah)
            cat > .config <<'EOF'
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f072"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_FLASH_START=0x8002000
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF
            ;;
    esac
    
    make olddefconfig &>/dev/null
    make -j$(nproc) &>/dev/null
    
    if [ -f "$klipper_dir/out/klipper.bin" ]; then
        echo -e "  ${C_GREEN}✓${NC} Klipper gebaut"
    else
        echo -e "  ${C_RED}✗${NC} Klipper Build fehlgeschlagen"
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    echo -e "${C_GREEN}Step 4/4: Flash Klipper via Katapult (CAN)${NC}"
    echo ""
    
    sleep 2
    
    echo "  Finde MCU auf CAN-Bus..."
    local can_uuid=""
    
    for i in {1..10}; do
        can_uuid=$(python3 ~/katapult/scripts/flash_can.py --scan 2>/dev/null | grep -oP 'can0\s+\K[0-9a-f]+' | head -1)
        if [ -n "$can_uuid" ]; then
            break
        fi
        sleep 1
    done
    
    if [ -n "$can_uuid" ]; then
        echo "  Gefunden: CAN UUID = $can_uuid"
        python3 ~/katapult/scripts/flash_can.py "$klipper_dir/out/klipper.bin" -i can0 -u "$can_uuid" &>/dev/null
        echo -e "  ${C_GREEN}✓${NC} Klipper geflasht!"
    else
        echo -e "  ${C_YELLOW}!${NC} MCU nicht gefunden. Bitte manuell flashen."
    fi
    
    echo ""
    draw_success "QUICK CAN SETUP ABGESCHLOSSEN!"
    echo ""
    
    echo -e "${C_CYAN}Füge dies in deine printer.cfg ein:${NC}"
    echo ""
    echo "[mcu can0]"
    echo "canbus_uuid: <YOUR_CAN_UUID>"
    echo ""
    echo "  Um UUID zu finden: ~/katapult/scripts/flash_can.py --scan"
    echo ""
    
    read -p "  Press Enter..."
}

#!/bin/bash

export TERM=xterm-256color

# --- THE FORGE: MCU FLASHING & DETECTION ---
source "$MODULES_DIR/system/mcu_builder.sh"

function run_flash_menu() {
    while true; do
        draw_header "⚒ THE FORGE - MCU MANAGER"
        
        echo "  ${C_GREEN}[1]${NC}  Auto-Flash          (Auto-detect via lsusb)"
        echo "  ${C_NEON}[2]${NC}  Quick CAN Setup     (1-Minute Wizard)"
        echo "  ${C_NEON}[3]${NC}  Manual Build        (make menuconfig)"
        echo "  ${C_NEON}[4]${NC}  AVRDude Flash       (For AVR microcontrollers)"
        echo "  ${C_NEON}[5]${NC}  View Logs"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) auto_flash_mcu ;;
            2) 
                if [ -f "$MODULES_DIR/hardware/can_manager.sh" ]; then
                    source "$MODULES_DIR/hardware/can_manager.sh"
                    run_can_manager
                else
                    log_error "Module missing: hardware/can_manager.sh"
                fi
                ;;
            3) manual_build ;;
            4) build_and_flash_avr ;;
            5) view_firmware_logs ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function auto_flash_mcu() {
    draw_header "⚡ MCU FLASHING - INTERACTIVE"
    
    echo "  Scanning for devices..."
    echo ""
    
    # 1. Show raw output for transparency (Community Standard)
    echo -e "${C_WHITE}USB BUS:${NC}"
    lsusb | sed 's/^/    /'
    echo ""
    
    # 2. Identify potential targets
    local targets=()
    local target_names=()
    
    # RP2040 (DFU or Mass Storage)
    if lsusb | grep -qi "2e8a:0003"; then
        targets+=("rp2040")
        target_names+=("RP2040 (RPI-RP2 / Pico / Toolhead)")
    fi
    # STM32 DFU (Standard)
    if lsusb | grep -qi "0483:df11"; then
        targets+=("stm32_dfu")
        target_names+=("STM32 DFU Bootloader (Octopus/SKR/MKS)")
    fi
    # Existing Klipper devices
    if [ -d "/dev/serial/by-id" ]; then
        local k_devs=$(ls /dev/serial/by-id/usb-Klipper_* 2>/dev/null)
        if [ -n "$k_devs" ]; then
            for d in $k_devs; do
                targets+=("serial:$d")
                target_names+=("Klipper Serial: $(basename $d)")
            done
        fi
    fi

    if [ ${#targets[@]} -eq 0 ]; then
        draw_error "No devices found in DFU or Serial mode."
        echo "  - RP2040: Hold BOOTSEL while connecting"
        echo "  - STM32: Use BOOT jumper and RESET"
        read -p "  Press Enter..."
        return
    fi

    echo -e "${C_NEON}Detected Targets:${NC}"
    for i in "${!targets[@]}"; do
        echo "    [$((i+1))] ${target_names[$i]}"
    done
    echo ""
    read -p "  Select device [1-${#targets[@]}] or [B]ack: " choice
    if [[ "$choice" =~ ^[bB]$ ]]; then return; fi
    
    local idx=$((choice - 1))
    if [ -z "${targets[$idx]}" ]; then log_error "Invalid selection"; return; fi

    local selected="${targets[$idx]}"
    
    # Selection logic based on target
    if [[ "$selected" == "rp2040" ]]; then
        build_and_flash_rp2040
    elif [[ "$selected" == "stm32_dfu" ]]; then
        build_and_flash_stm32
    elif [[ "$selected" == serial:* ]]; then
        local dev_path="${selected#serial:}"
        log_info "Serial flashing not yet fully automated. Please use manual build."
        echo "  Target: $dev_path"
        read -p "  Press Enter..."
    fi
}

function build_and_flash_rp2040() {
    draw_header "RP2040 FIRMWARE BUILD"
    local klipper_dir="$HOME/klipper"
    
    cd "$klipper_dir"
    log_info "Compiling RP2040 (Generic)..."
    
    # Headless config injection
    make clean >/dev/null 2>&1
    cat > .config <<'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_RP2040=y
CONFIG_MCU="rp2040"
CONFIG_BOARD_DIRECTORY="rp2040"
CONFIG_FLASH_SIZE=0x200000
CONFIG_FLASH_START=0x10000
CONFIG_RP2040_FLASH_START_2000=y
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
    
    make olddefconfig >/dev/null 2>&1
    make -j$(nproc)
    
    if [ ! -f "out/klipper.uf2" ]; then
        draw_error "Build failed! Check logs."
        read -p "  Press Enter..."
        return
    fi
    
    draw_success "Build complete: out/klipper.uf2"
    echo ""
    echo -e "${C_WHITE}COMMUNITY STANDARD FLASHING:${NC}"
    echo "  1. Ensure your RP2040 is in BOOTSEL mode."
    echo "  2. The device should appear as a USB drive (RPI-RP2)."
    echo "  3. Mount the drive if your OS hasn't done so."
    echo "  4. Execute command:"
    echo -e "     ${C_NEON}cp $klipper_dir/out/klipper.uf2 /PATH/TO/MOUNT/POINT/${NC}"
    echo ""
    echo "  [i] Automated mounting is often unreliable across different OS versions"
    echo "      and is avoided to prevent filesystem corruption."
    echo ""
    read -p "  Press Enter when done..."
}

function build_and_flash_stm32() {
    draw_header "STM32 FIRMWARE BUILD & FLASH"
    local klipper_dir="$HOME/klipper"
    
    # We use F446 as common default if user doesn't specify
    log_info "Compiling for STM32F446 (Default 8008000 offset)..."
    
    cd "$klipper_dir"
    make clean >/dev/null 2>&1
    cat > .config <<'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_MCU="stm32f446"
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_STM32_CLOCK_REF_12M=y
CONFIG_STM32F446_SELECT=y
CONFIG_FLASH_START=0x8008000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
    
    make olddefconfig >/dev/null 2>&1
    make -j$(nproc)
    
    if [ ! -f "out/klipper.bin" ]; then
        draw_error "Build failed!"
        read -p "  Press Enter..."
        return
    fi
    
    draw_success "Build complete: out/klipper.bin"
    echo ""
    
    if lsusb | grep -q "0483:df11"; then
        log_info "STM32 DFU detected. Preparing to flash..."
        echo "  Command: dfu-util -a 0 -d 0483:df11 -D out/klipper.bin -s 0x08008000:leave"
        read -p "  Continue with Flash? [y/N] " yn
        if [[ "$yn" =~ ^[yY]$ ]]; then
            sudo dfu-util -a 0 -d 0483:df11 -D out/klipper.bin -s 0x08008000:leave
            [ $? -eq 0 ] && log_success "Flash complete!" || log_error "Flash failed!"
        fi
    else
        log_warn "DFU device lost or not found."
        echo "  Please use the Manual SD Card method:"
        echo -e "  Copy ${C_NEON}$klipper_dir/out/klipper.bin${NC} to SD card"
        echo "  Rename to 'firmware.bin' and restart MCU."
    fi
    
    read -p "  Press Enter..."
}

function build_and_flash_avr() {
    draw_header "BUILD & FLASH AVR FIRMWARE"
    # (Existing AVR logic remains standard)
    draw_header "BUILD & FLASH AVR FIRMWARE"
    
    local klipper_dir="$HOME/klipper"
    cd "$klipper_dir"
    
    echo "  Select AVR board:"
    echo "  [1] ATmega328P (Arduino Uno/Nano)"
    echo "  [2] ATmega2560 (Arduino Mega)"
    echo "  [3] ATmega1284P"
    read -p "  Option: " avr_opt
    
    local mcu=""
    case $avr_opt in
        1) mcu="atmega328p" ;;
        2) mcu="atmega2560" ;;
        3) mcu="atmega1284p" ;;
        *) log_error "Invalid selection"; return ;;
    esac
    
    log_info "Cleaning..."
    make clean >/dev/null 2>&1
    rm -f .config
    
    log_info "Generating AVR $mcu config..."
    cat > .config <<EOF
CONFIG_MACH_AVR=y
CONFIG_MCU="$mcu"
CONFIG_AVR_BOARD_DIRECTORY="$mcu"
EOF
    
    make olddefconfig 2>&1 | tail -5
    make -j$(nproc) 2>&1 | tail -20
    
    echo ""
    echo "  Build output:"
    ls -la "$klipper_dir/out/" | grep -i klipper || true
    
    if [ -f "$klipper_dir/out/klipper.hex" ]; then
        log_success "Firmware built: klipper.hex"
        echo ""
        
        # Check for programmer
        echo "  Select programmer:"
        echo "  [1] USBasp"
        echo "  [2] AVRISP mkII"
        echo "  [3] Arduino (bootloader)"
        read -p "  Option: " prog_opt
        
        local prog=""
        local device=""
        case $prog_opt in
            1) prog="usbasp"; device="$mcu" ;;
            2) prog="avrispmkII"; device="$mcu" ;;
            3) prog="arduino"; device="$mcu" ;;
            *) log_error "Invalid selection"; return ;;
        esac
        
        log_info "Flashing via AVRDude..."
        sudo avrdude -c $prog -p $device -U flash:w:"$klipper_dir/out/klipper.hex":i
        log_success "Flash complete!"
    else
        log_error "Build failed!"
    fi
    
    read -p "  Press Enter..."
}

function view_firmware_logs() {
    draw_header "FIRMWARE BUILD LOGS"
    
    if [ -f "$HOME/klipper/make.log" ]; then
        tail -50 "$HOME/klipper/make.log"
    else
        echo "  No build logs found."
    fi
    
    read -p "  Press Enter..."
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

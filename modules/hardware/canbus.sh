#!/bin/bash

# --- CAN-BUS & HARDWARE MODULE ---

function scan_cub_devices() {
    echo -e "${C_CYAN}>> Scanning USB Bus...${NC}"
    
    # 1. LSUSB Scan for vendor IDs
    local usb_devices=$(lsusb)
    
    # 2. Serial by-id Scan
    local serial_devices=(/dev/serial/by-id/*)
    
    if [ ! -e "${serial_devices[0]}" ]; then
        echo -e "${C_WARN}No serial devices found in /dev/serial/by-id/${NC}"
    else
        echo -e "${C_GREEN}Found Serial Devices:${NC}"
        printf '%s\n' "${serial_devices[@]}"
    fi
}

function configure_can_network() {
    echo -e "${C_CYAN}>> Generating CAN Network Config...${NC}"

    local can_iface="${KATANA_CAN_INTERFACE:-can0}"
    local bitrate="${KATANA_CAN_BITRATE:-1000000}"
    local txqueuelen="${KATANA_CAN_TXQUEUELEN:-1024}"

    local config_file="/etc/network/interfaces.d/$can_iface"
    
    # Check if file exists to avoid accidental overwrite without backup
    if [ -f "$config_file" ]; then
         echo -e "${C_WARN}Config $config_file already exists. Backing up...${NC}"
         sudo cp "$config_file" "${config_file}.bak.$(date +%s)"
    fi
    
    # Generate content
    # Write CAN0 config
    
    local config_content="allow-hotplug $can_iface
iface $can_iface can static
    bitrate $bitrate
    up ip link set $can_iface txqueuelen $txqueuelen
    up ifconfig $can_iface txqueuelen $txqueuelen"

    echo -e "$config_content" | sudo tee "$config_file" > /dev/null
    
    echo -e "${C_GREEN}Successfully created $config_file${NC}"
    echo -e "Settings: Bitrate=$bitrate, TXQueueLen=$txqueuelen"
}

function flash_firmware_menu() {
    local type=$1 # "klipper" or "katapult"
    echo -e "${C_CYAN}>> Select Target Board for $type:${NC}"
    
    # Board Database (Simple Array for now)
    echo "1) BTT Octopus Pro (STM32F446)"
    echo "2) BTT Octopus Pro (STM32F429)"
    echo "3) BTT EBB36/42 v1.1/v1.2 (STM32G0B1)"
    echo "4) BTT SB2209 (STM32G0B1)"
    echo "5) BTT SB2209 (RP2040)"
    echo "6) MKS SKIPR (STM32F407)"
    echo "x) Cancel"
    
    read -p "  >> BOARD: " board_choice
    
    case $board_choice in
        1) setup_config_stm32f446 "$type" ;;
        2) setup_config_stm32f429 "$type" ;;
        3) setup_config_stm32g0b1 "$type" ;;
        4) setup_config_stm32g0b1 "$type" ;; # Same MCU
        5) setup_config_rp2040 "$type" ;;
        6) setup_config_stm32f407 "$type" ;;
        [xX]) return ;;
        *) echo "Invalid"; return ;;
    esac
}

# --- CONFIG PRESETS ---
# These functions seek to emulate "make menuconfig" by setting Kconfig values directly into .config

function set_kconfig_value() {
    local key=$1
    local value=$2
    local config_file=".config"
    
    # Check if key exists
    if grep -q "^$key=" "$config_file"; then
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
    elif grep -q "^# $key is not set" "$config_file"; then
        sed -i "s/^# $key is not set/$key=$value/" "$config_file"
    else
        echo "$key=$value" >> "$config_file"
    fi
}

function compile_and_flash() {
    local target_dir=$1
    
    echo -e "${C_CYAN}>> Compiling...${NC}"
    cd "$target_dir" || return
    
    make clean
    make -j4
    
    echo -e "${C_GREEN}>> Compilation Complete.${NC}"
    echo -e "${C_WARN}>> MAKE SURE THE BOARD IS IN DFU MODE!${NC}"
    read -p "Press Enter to FLASH (or Ctrl+C to abort)..."
    
    # Attempt DFU flash
    make flash FLASH_DEVICE=0483:df11 # Generic STM32 DFU ID, might need adjustment
    
    # TODO: Handle Mass Storage flashing for some boards (RP2040)
    # detecting /Volumes/RPI-RP2 or similar on Mac/Linux? 
    # Actually on Linux it's usually mounted in /media/ or /mnt/
}

function setup_config_stm32f446() {
    local type=$1
    local target_dir
    local can_bitrate="${KATANA_CAN_BITRATE:-1000000}"

    if [ "$type" == "klipper" ]; then
        target_dir="$HOME/klipper"
    else
        target_dir="$HOME/katapult"
    fi

    echo -e "${C_CYAN}>> Configuring for STM32F446 ($type)...${NC}"

    if [ ! -d "$target_dir" ]; then
        echo -e "${C_RED}Error: $target_dir not found.${NC}"
        return
    fi

    cd "$target_dir" || { log_error "Directory not found: $target_dir"; return 1; }

    make clean

    cat > .config <<EOF
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f446"
CONFIG_CLOCK_FREQ=180000000
EOF

    if [ "$type" == "katapult" ]; then
        cat >> .config <<EOF
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x80000
CONFIG_RAM_START=0x20000000
CONFIG_RAM_SIZE=0x20000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    else
        cat >> .config <<EOF
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    fi

    # Run olddefconfig to fill in defaults
    make olddefconfig
    
    compile_and_flash "$target_dir"
}

# --- PLACEHOLDERS FOR OTHER BOARDS (Similar logic needed) ---
# For brevity in this turn, I'm setting up the structure.
function setup_config_stm32f429() {
    local type=$1
    local target_dir
    local can_bitrate="${KATANA_CAN_BITRATE:-1000000}"
    if [ "$type" == "klipper" ]; then target_dir="$HOME/klipper"; else target_dir="$HOME/katapult"; fi

    echo -e "${C_CYAN}>> Configuring for STM32F429 (Octopus Pro) ($type)...${NC}"
    if [ ! -d "$target_dir" ]; then echo -e "${C_RED}Error: $target_dir not found.${NC}"; return; fi
    cd "$target_dir" || { log_error "Directory not found: $target_dir"; return 1; }
    make clean

    cat > .config <<EOF
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f429"
CONFIG_CLOCK_FREQ=180000000
EOF

    if [ "$type" == "katapult" ]; then
        cat >> .config <<EOF
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x80000
CONFIG_RAM_START=0x20000000
CONFIG_RAM_SIZE=0x30000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    else
        cat >> .config <<EOF
CONFIG_STM32_CANBUS_PA11_PA12=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    fi
    make olddefconfig
    compile_and_flash "$target_dir"
}

function setup_config_stm32g0b1() {
    local type=$1
    local target_dir
    local can_bitrate="${KATANA_CAN_BITRATE:-1000000}"
    if [ "$type" == "klipper" ]; then target_dir="$HOME/klipper"; else target_dir="$HOME/katapult"; fi

    echo -e "${C_CYAN}>> Configuring for STM32G0B1 (EBB/SB2209) ($type)...${NC}"
    if [ ! -d "$target_dir" ]; then echo -e "${C_RED}Error: $target_dir not found.${NC}"; return; fi
    cd "$target_dir" || { log_error "Directory not found: $target_dir"; return 1; }
    make clean

    cat > .config <<EOF
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32g0b1"
CONFIG_CLOCK_FREQ=64000000
EOF

    if [ "$type" == "katapult" ]; then
        cat >> .config <<EOF
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x20000
CONFIG_RAM_START=0x20000000
CONFIG_RAM_SIZE=0x24000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
CONFIG_CANBUS_PB0_PB1=y
EOF
    else
        cat >> .config <<EOF
CONFIG_FLASH_START=0x8002000
CONFIG_STM32_CANBUS_PB0_PB1=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    fi
    make olddefconfig
    compile_and_flash "$target_dir"
}

function setup_config_rp2040() {
    local type=$1
    local target_dir
    local can_bitrate="${KATANA_CAN_BITRATE:-1000000}"
    if [ "$type" == "klipper" ]; then target_dir="$HOME/klipper"; else target_dir="$HOME/katapult"; fi

    echo -e "${C_CYAN}>> Configuring for RP2040 (SB2209) ($type)...${NC}"
    if [ ! -d "$target_dir" ]; then echo -e "${C_RED}Error: $target_dir not found.${NC}"; return; fi
    cd "$target_dir" || { log_error "Directory not found: $target_dir"; return 1; }
    make clean

    cat > .config <<EOF
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_RP2040=y
CONFIG_BOARD_DIRECTORY="rp2040"
CONFIG_MCU="rp2040"
CONFIG_CLOCK_FREQ=12000000
EOF

    if [ "$type" == "katapult" ]; then
        cat >> .config <<EOF
CONFIG_FLASH_SIZE=0x200000
CONFIG_RP2040_SELECT=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
CONFIG_CANBUS_GPIO_TX=28
CONFIG_CANBUS_GPIO_RX=29
EOF
    else
        cat >> .config <<EOF
CONFIG_RP2040_FLASH_START_2000=y
CONFIG_RP2040_CANBUS_GPIO28_GPIO29=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    fi
    make olddefconfig
    compile_and_flash "$target_dir"
}

function setup_config_stm32f407() {
    local type=$1
    local target_dir
    local can_bitrate="${KATANA_CAN_BITRATE:-1000000}"
    if [ "$type" == "klipper" ]; then target_dir="$HOME/klipper"; else target_dir="$HOME/katapult"; fi

    echo -e "${C_CYAN}>> Configuring for STM32F407 (MKS SKIPR) ($type)...${NC}"
    if [ ! -d "$target_dir" ]; then echo -e "${C_RED}Error: $target_dir not found.${NC}"; return; fi
    cd "$target_dir" || { log_error "Directory not found: $target_dir"; return 1; }
    make clean

    cat > .config <<EOF
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f407"
CONFIG_CLOCK_FREQ=168000000
EOF

    if [ "$type" == "katapult" ]; then
        cat >> .config <<EOF
CONFIG_FLASH_START=0x8000000
CONFIG_FLASH_SIZE=0x80000
CONFIG_RAM_START=0x20000000
CONFIG_RAM_SIZE=0x20000
CONFIG_STM32_SELECT=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    else
        cat >> .config <<EOF
CONFIG_FLASH_START=0x800c000
CONFIG_STM32_CANBUS_PD0_PD1=y
CONFIG_CANBUS_FREQUENCY=$can_bitrate
EOF
    fi
    make olddefconfig
    compile_and_flash "$target_dir"
}

function forge_wizard() {
    clear
    draw_top
    print_box_line " ${C_TXT}THE FORGE: CAN-BUS MASTER${NC}"
    draw_line
    
    echo -e "${C_CYAN}1. Scan USB/Serial Devices${NC}"
    echo -e "${C_CYAN}2. Flash Katapult (CanBoot)${NC}"
    echo -e "${C_CYAN}3. Flash Klipper${NC}"
    echo -e "${C_CYAN}4. Generate Network Config (${KATANA_CAN_INTERFACE:-can0})${NC}"
    echo -e "${C_GREY}X. Back${NC}"
    
    read -p "  >> CHOICE: " forge_choice
    
    case $forge_choice in
        1)
            scan_cub_devices
            read -p "Press Enter to continue..."
            forge_wizard
            ;;
        2)
            flash_firmware_menu "katapult"
            read -p "Press Enter to continue..."
            forge_wizard
            ;;
        3)
            flash_firmware_menu "klipper"
            read -p "Press Enter to continue..."
            forge_wizard
            ;;
        4)
            configure_can_network
            read -p "Press Enter to continue..."
            forge_wizard
            ;;
        [xX])
            return
            ;;
        *)
            forge_wizard
            ;;
    esac
}

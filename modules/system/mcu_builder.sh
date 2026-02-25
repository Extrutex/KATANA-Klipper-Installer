#!/bin/bash
# ==============================================================================
# KATANA MCU BUILDER - Automated Firmware Builder
# ==============================================================================

export TERM=xterm-256color

KLIPPER_DIR="$HOME/klipper"
CONFIG_PATH="$KLIPPER_DIR/.config"

function run_quick_build_menu() {
    draw_header "QUICK BUILD - PRECONFIGURED BOARDS"
    
    echo ""
    echo "  Select Board:"
    echo ""
    echo "    [1] BigTreeTech Octopus F446 v1.1 (12MHz)"
    echo "    [2] BigTreeTech Octopus Pro F429 (12MHz)"
    echo "    [3] BigTreeTech Octopus Pro H723 (25MHz)"
    echo "    [4] Raspberry Pi RP2040 (Generic)"
    echo "    [5] BigTreeTech SKR E3 Turbo (STM32F407)"
    echo "    [6] Fysetc Cheetah v2.0 (STM32F172)"
    echo "    [7] Mellow Fly Gemini S (STM32H743)"
    echo "    [8] BTT GTR v1.0 (STM32H743)"
    echo "    [9] BTT E3 RRF v1.1 (STM32F429)"
    echo ""
    echo "    [B] Back to FORGE"
    echo ""
    
    local ch
    read -r -p "  >> Choose: " ch
    
    case $ch in
        1) build_mcu "btt_octopus_f446_v1.1" ;;
        2) build_mcu "btt_octopus_pro_f429" ;;
        3) build_mcu "btt_octopus_pro_h723" ;;
        4) build_mcu "rp2040_generic" ;;
        5) build_mcu "btt_skr_e3_turbo" ;;
        6) build_mcu "fysetc_cheetah_v2" ;;
        7) build_mcu "fly_gemini_s_h743" ;;
        8) build_mcu "btt_gtr_v1" ;;
        9) build_mcu "btt_e3_rrf_v1" ;;
        b|B) return ;;
        *) 
            echo ""
            echo "  Invalid selection. Press Enter to continue."
            read
            ;;
    esac
}

function build_mcu() {
    local board_key="$1"
    
    draw_header "BUILDING FIRMWARE FOR: $board_key"
    
    # Check if Klipper is installed
    if [ ! -d "$KLIPPER_DIR" ]; then
        draw_error "Klipper not installed! Install Klipper first (Option 2 → 1)."
        read -r -p "  Press Enter..."
        return 1
    fi
    
    log_info "Starting build for: $board_key"
    
    # Get config based on board
    local config_map=$(get_board_config "$board_key")
    
    if [ -z "$config_map" ]; then
        draw_error "Board not found in database: $board_key"
        read -r -p "  Press Enter..."
        return 1
    fi
    
    # Write .config
    log_info "Writing .config file..."
    echo "$config_map" > "$CONFIG_PATH"
    
    # Clean and compile
    log_info "Cleaning previous builds..."
    cd "$KLIPPER_DIR" || { log_error "Klipper directory not found"; return 1; }
    make clean > /dev/null 2>&1
    
    log_info "Validating config..."
    make olddefconfig > /dev/null 2>&1
    
    log_info "Compiling firmware (this takes a moment)..."
    make -j$(nproc)
    local build_result=$?
    
    if [ $build_result -eq 0 ] && [ -f "$KLIPPER_DIR/out/klipper.bin" ]; then
        draw_success "Build SUCCESS!"
        echo ""
        echo "  Firmware: $KLIPPER_DIR/out/klipper.bin"
        echo ""
        echo "  Next steps:"
        echo "  1. Copy klipper.bin to SD card"
        echo "  2. Rename to firmware.bin"
        echo "  3. Flash to MCU"
        echo ""
    elif [ -f "$KLIPPER_DIR/out/klipper.elf.hex" ]; then
        draw_success "Build SUCCESS!"
        echo ""
        echo "  Firmware: $KLIPPER_DIR/out/klipper.elf.hex"
        echo ""
        echo "  Next steps:"
        echo "  1. Copy klipper.elf.hex to SD card"
        echo "  2. Rename to firmware.bin"
        echo "  3. Flash to MCU"
        echo ""
    else
        draw_error "Build FAILED! Exit code: $build_result"
    fi
    
    read -r -p "  Press Enter..."
}

function get_board_config() {
    local board="$1"
    
    case "$board" in
        "btt_octopus_f446_v1.1")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f446"
CONFIG_STM32_CLOCK_REF_12M=y
CONFIG_STM32F446_SELECT=y
CONFIG_FLASH_START=0x8008000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "btt_octopus_pro_f429")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f429"
CONFIG_STM32_CLOCK_REF_12M=y
CONFIG_STM32F429_SELECT=y
CONFIG_FLASH_START=0x8008000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "btt_octopus_pro_h723")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32h723"
CONFIG_STM32_CLOCK_REF_25M=y
CONFIG_STM32H723_SELECT=y
CONFIG_FLASH_START=0x8020000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "rp2040_generic")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_RP2040=y
CONFIG_BOARD_DIRECTORY="rp2040"
CONFIG_MCU="rp2040"
CONFIG_FLASH_START=0x10000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "btt_skr_e3_turbo")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f407"
CONFIG_STM32_CLOCK_REF_8M=y
CONFIG_STM32F407_SELECT=y
CONFIG_FLASH_START=0x8008000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "fysetc_cheetah_v2")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f172"
CONFIG_STM32_CLOCK_REF_8M=y
CONFIG_STM32F172_SELECT=y
CONFIG_FLASH_START=0x8004000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "fly_gemini_s_h743")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32h743"
CONFIG_STM32_CLOCK_REF_25M=y
CONFIG_STM32H743_SELECT=y
CONFIG_FLASH_START=0x8020000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "btt_gtr_v1")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32h743"
CONFIG_STM32_CLOCK_REF_25M=y
CONFIG_STM32H743_SELECT=y
CONFIG_FLASH_START=0x8020000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        "btt_e3_rrf_v1")
            cat << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_BOARD_DIRECTORY="stm32"
CONFIG_MCU="stm32f429"
CONFIG_STM32_CLOCK_REF_12M=y
CONFIG_STM32F429_SELECT=y
CONFIG_FLASH_START=0x8008000
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
EOF
            ;;
        *)
            echo ""
            ;;
    esac
}

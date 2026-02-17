#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE FORGE HAL (Flash Engine)
# Usage: Automated Firmware Compilation & Flashing
# Workflow: Wizard Style (Enforced Sequence)
# ==============================================================================

function run_hal_flasher() {
    while true; do
        draw_header "THE FORGE HAL - FIRMWARE WIZARD"
        echo "  Firmware Building (Klipper):"
        echo "  [1] STM32 (Voron V2.4, Trident, Switchwire)"
        echo "  [2] RP2040 (Raspberry Pi Pico, BTT SKR Pico)"
        echo "  [3] Linux Process (Raspberry Pi as Host MCU)"
        echo "  [4] AVR (Older 8-bit boards)"
        echo ""
        echo "  [5] Katapult (CanBoot) Manager"
        echo "  [6] Toolboard Wizard (Nitehawk, SB2209, EBB)"
        echo ""
        echo "  [B] Back"
        
        read -p "  >> SELECT: " arch
        case $arch in
            1) run_wizard "STM32" ;;
            2) run_wizard "RP2040" ;;
            3) run_linux_wizard ;;
            4) run_wizard "AVR" ;;
            5) 
               if [ -f "$MODULES_DIR/hardware/katapult_manager.sh" ]; then
                   source "$MODULES_DIR/hardware/katapult_manager.sh"
                   run_katapult_menu
               else
                   log_error "Katapult module missing."
               fi
               ;;
            6)
               if [ -f "$MODULES_DIR/hardware/toolboard_wizard.sh" ]; then
                   source "$MODULES_DIR/hardware/toolboard_wizard.sh"
                   run_toolboard_wizard
               else
                   log_error "Toolboard Wizard module missing."
               fi
               ;;
            b|B) return ;;
        esac
    done
}

function run_linux_wizard() {
    draw_header "LINUX HOST MCU WIZARD"
    echo "  Step 1: Configuration & Build"
    echo "  ---------------------------------------------------"
    echo "  This will compile Klipper for the Raspberry Pi itself."
    echo ""
    read -p "  Press Enter to start..."
    
    cd ~/klipper || { log_error "Klipper dir not found"; return; }
    
    # Pre-seed config for Linux Process
    echo "CONFIG_LOW_LEVEL_OPTIONS=y" > .config
    echo "CONFIG_MACH_LINUX=y" >> .config
    
    make olddefconfig
    make clean
    
    log_info "Compiling (make)..."
    if make; then
        log_success "Build Complete!"
    else
        log_error "Build Failed."
        read -p "  Press Enter..."
        return
    fi

    echo ""
    echo "  Step 2: Installation & Flashing"
    echo "  ---------------------------------------------------"
    read -p "  Press Enter to install/flash..."
    
    if make flash; then
        log_success "Flashed Successfully!"
        
        # Ensure service is set up
        if [ ! -f "/etc/systemd/system/klipper-mcu.service" ]; then
            log_info "Registering klipper-mcu service..."
            sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/
            sudo systemctl enable klipper-mcu.service
            sudo systemctl daemon-reload
        fi
        
        sudo systemctl restart klipper-mcu.service
        log_success "Service klipper-mcu restarted."
    else
        log_error "Installation failed."
    fi
    read -p "  Press Enter to finish..."
}

function run_wizard() {
    local arch_name="$1"
    draw_header "WIZARD: $arch_name"
    
    cd ~/klipper || return
    
    echo "  Step 1: Configuration"
    echo "  ---------------------------------------------------"
    echo "  I will open 'menuconfig' now."
    echo "  Please select your settings for $arch_name."
    echo ""
    read -p "  Press Enter to configure..."
    
    if ! make menuconfig; then
        log_error "Menuconfig cancelled or failed."
        return
    fi
    
    echo ""
    echo "  Step 2: Building Firmware"
    echo "  ---------------------------------------------------"
    log_info "Cleaning old build..."
    make clean > /dev/null
    
    log_info "Compiling (make -j4)..."
    if make -j4; then
        log_success "Firmware Compiled: out/klipper.bin"
    else
        log_error "Build failed."
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    echo "  Step 3: Flashing"
    echo "  ---------------------------------------------------"
    echo "  How do you want to flash this firmware?"
    echo ""
    echo "  [1] USB Cable (DFU / Bootloader mode)"
    echo "  [2] SD Card (Manual Copy)"
    echo "  [3] CAN Bus (Katapult)"
    echo "  [S] Skip / Finish"
    echo ""
    
    read -p "  >> METHOD: " method
    case $method in
        1)
            log_info "Attempting USB Flash (make flash)..."
            echo "  Please ensure the device is in DFU/Bootloader mode!"
            read -p "  Press Enter when ready..."
            make flash
            ;;
        2)
            log_info "SD CARD INSTRUCTIONS:"
            echo "  1. Connect SD Card to PC."
            echo "  2. The file is at: ~/klipper/out/klipper.bin"
            echo "  3. Use SCP/WinSCP to download it."
            echo "  4. Rename to 'firmware.bin' (usually)."
            echo "  5. Put on SD card, insert in MCU, restart."
            ;;
        3)
             if [ -f "$KATANA_ROOT/scripts/can_scanner.py" ]; then
                 python3 "$KATANA_ROOT/scripts/can_scanner.py"
                 read -p "  Enter UUID to flash: " uuid
                 python3 lib/canboot/flash_can.py -u $uuid
            else
                echo "  Scanner module missing."
            fi
            ;;
    esac
    
    read -p "  Wizard Complete. Press Enter..."
}

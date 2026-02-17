#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE FORGE HAL (Flash Engine)
# Usage: Automated Firmware Compilation & Flashing
# Workflow: Wizard Style (Enforced Sequence)
# Rule: Flash method is determined by build artifact, NOT user choice
# ==============================================================================

function run_hal_flasher() {
    while true; do
        draw_header "THE FORGE HAL - FIRMWARE WIZARD"
        echo "  Select MCU Architecture:"
        echo "  [1] STM32"
        echo "  [2] RP2040"
        echo "  [3] Linux Process (Raspberry Pi as Host MCU)"
        echo "  [4] AVR"
        echo ""
        echo "  [5] Katapult (CanBoot) Manager"
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
    
    if [ ! -d "$HOME/klipper" ]; then
        log_error "Klipper is not installed!"
        echo "  You need to install Klipper first via Quick Start [1]."
        echo ""
        read -p "  Press Enter..."
        return
    fi
    cd ~/klipper
    
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
    
    if [ ! -d "$HOME/klipper" ]; then
        log_error "Klipper is not installed!"
        echo "  You need to install Klipper first via Quick Start [1]."
        echo ""
        read -p "  Press Enter..."
        return
    fi
    cd ~/klipper
    
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
        log_success "Firmware Compiled!"
    else
        log_error "Build failed."
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    echo "  Step 3: Flashing"
    echo "  ---------------------------------------------------"
    
    # === ARTIFACT-BASED FLASH DETECTION ===
    # The flash method is determined by the build output, not user choice.
    # This follows KATANA Rule: "Artifact-Selector"
    
    if [ "$arch_name" = "RP2040" ]; then
        # RP2040 Safety Lock: Only UF2 mass-storage flash
        flash_rp2040
    elif [ -f "out/klipper.uf2" ]; then
        # UF2 artifact found (RP2040 variant)
        flash_rp2040
    elif [ -f "out/klipper.bin" ]; then
        # .bin artifact: STM32 or similar
        flash_bin_artifact "$arch_name"
    elif [ -f "out/klipper.elf.hex" ]; then
        # AVR hex file
        flash_avr_artifact
    else
        log_error "No known firmware artifact found in out/"
        echo "  Expected: klipper.bin, klipper.uf2, or klipper.elf.hex"
        ls -la out/ 2>/dev/null
    fi
    
    read -p "  Wizard Complete. Press Enter..."
}

# === FLASH METHODS (Auto-Selected) ===

function flash_rp2040() {
    echo ""
    echo "  ${C_GREEN}Detected: RP2040 (UF2 Flash)${NC}"
    echo "  ---------------------------------------------------"
    echo "  RP2040 boards flash via USB Mass Storage (UF2)."
    echo ""
    echo "  Instructions:"
    echo "    1. Hold BOOTSEL button on the board"
    echo "    2. Connect USB (or tap RESET while holding BOOTSEL)"
    echo "    3. A USB drive named 'RPI-RP2' should appear"
    echo ""
    
    # Auto-detect mounted RP2040
    local rp2_mount=""
    for mount_point in /media/*/RPI-RP2 /mnt/RPI-RP2 /media/RPI-RP2; do
        if [ -d "$mount_point" ]; then
            rp2_mount="$mount_point"
            break
        fi
    done
    
    if [ -n "$rp2_mount" ]; then
        log_success "Found RP2040 at: $rp2_mount"
        read -p "  Copy firmware now? [Y/n]: " yn
        if [[ ! "$yn" =~ ^[nN] ]]; then
            local uf2_file="out/klipper.uf2"
            if [ ! -f "$uf2_file" ]; then
                # Fallback: some builds produce .bin; convert with elf2uf2 if available
                log_warn "No .uf2 found. Looking for alternative..."
                if [ -f "out/klipper.bin" ]; then
                    uf2_file="out/klipper.bin"
                fi
            fi
            cp "$uf2_file" "$rp2_mount/" && log_success "Firmware copied! Board will reboot."
        fi
    else
        echo "  ${C_YELLOW}RP2040 not detected as USB drive.${NC}"
        echo "  Please put board in BOOTSEL mode and try again,"
        echo "  or manually copy: out/klipper.uf2 → RPI-RP2 drive"
    fi
}

function flash_bin_artifact() {
    local arch_name="$1"
    echo ""
    echo "  ${C_GREEN}Detected: .bin firmware (${arch_name})${NC}"
    echo "  ---------------------------------------------------"
    
    # Check if a DFU device is connected
    local dfu_found=0
    if command -v dfu-util &> /dev/null; then
        if dfu-util -l 2>/dev/null | grep -q "Found DFU"; then
            dfu_found=1
        fi
    fi
    
    if [ $dfu_found -eq 1 ]; then
        echo "  ${C_GREEN}DFU device detected!${NC}"
        echo ""
        echo "  [1] Flash via DFU (USB)"
        echo "  [2] SD Card (Manual Copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
        echo ""
        read -p "  >> METHOD: " method
    else
        echo "  No DFU device detected."
        echo ""
        echo "  [1] SD Card (Manual Copy)"
        echo "  [2] CAN Bus (Katapult)"
        echo "  [S] Skip"
        echo ""
        read -p "  >> METHOD: " method
        # Shift method numbers since DFU is not an option
        case $method in
            1) method=2 ;;
            2) method=3 ;;
        esac
    fi
    
    case $method in
        1)
            log_info "Flashing via DFU..."
            echo "  Ensure the device is in DFU/Bootloader mode!"
            read -p "  Press Enter when ready..."
            make flash
            ;;
        2)
            log_info "SD CARD INSTRUCTIONS:"
            echo "  1. The firmware file is at: ~/klipper/out/klipper.bin"
            echo "  2. Download it via SCP/WinSCP to your computer."
            echo "  3. Rename to 'firmware.bin' (check your board's docs)."
            echo "  4. Copy to a FAT32-formatted SD card."
            echo "  5. Insert SD card into MCU, power cycle the board."
            echo ""
            echo "  ${C_YELLOW}[!] Some boards need a unique filename each flash.${NC}"
            ;;
        3)
            flash_via_can
            ;;
    esac
}

function flash_avr_artifact() {
    echo ""
    echo "  ${C_GREEN}Detected: AVR Hex firmware${NC}"
    echo "  ---------------------------------------------------"
    echo "  AVR boards flash via USB using avrdude."
    echo ""
    
    log_info "Attempting flash (make flash)..."
    echo "  Ensure the board is connected via USB!"
    read -p "  Press Enter when ready..."
    make flash
}

function flash_via_can() {
    echo ""
    log_info "CAN Bus Flashing (Katapult/CanBoot)"
    echo "  ---------------------------------------------------"
    
    # Scan for CAN devices
    if [ -f "$KATANA_ROOT/scripts/can_scanner.py" ]; then
        python3 "$KATANA_ROOT/scripts/can_scanner.py"
    else
        # Try standard interface query
        echo "  Querying CAN interface..."
        if command -v candump &> /dev/null && ip link show can0 &> /dev/null; then
            echo "  CAN0 interface found."
        else
            log_warn "CAN interface not detected. Ensure can0 is configured."
        fi
    fi
    
    read -p "  Enter UUID to flash: " uuid
    if [ -z "$uuid" ]; then
        log_error "No UUID provided."
        return
    fi
    
    # Dynamic detection of flash tool (Klipper evolves directory structure)
    if [ -f "lib/canboot/flash_can.py" ]; then
        python3 lib/canboot/flash_can.py -u "$uuid"
    elif [ -f "lib/katapult/flash_can.py" ]; then
        python3 lib/katapult/flash_can.py -u "$uuid"
    elif [ -f "../katapult/scripts/flashtool.py" ]; then
        python3 ../katapult/scripts/flashtool.py -u "$uuid"
    else
        log_error "Could not find flash_can.py or flashtool.py"
        echo "  Ensure Katapult is installed (use Katapult Manager from main menu)."
    fi
}

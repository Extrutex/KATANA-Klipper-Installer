#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE FORGE (Flash Engine)
# Usage: Firmware Build & Flash - KIAUH-style simplicity
# Rule: Flash method is determined by build artifact, NOT user choice
# ==============================================================================

function run_hal_flasher() {
    while true; do
        draw_header "🔧 THE FORGE - Build & Flash Firmware"
        echo ""
        echo "  ${C_GREEN}[1]${NC}  Build & Flash Firmware     (opens menuconfig)"
        echo "  ${C_NEON}[2]${NC}  Linux Host MCU             (automatic, no config needed)"
        echo "  ${C_NEON}[3]${NC}  Katapult (CanBoot) Manager"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> SELECT: " choice
        case $choice in
            1) run_build_and_flash ;;
            2) run_linux_wizard ;;
            3)
               if [ -f "$MODULES_DIR/hardware/katapult_manager.sh" ]; then
                   source "$MODULES_DIR/hardware/katapult_manager.sh"
                   run_katapult_menu
               else
                   log_error "Katapult module missing."
                   read -p "  Press Enter..."
               fi
               ;;
            b|B) return ;;
        esac
    done
}

# === BUILD & FLASH (KIAUH-Style) ===
# Opens menuconfig directly. User picks architecture + settings there.
# After build, flash method is auto-detected from the build artifact.

function run_build_and_flash() {
    draw_header "BUILD & FLASH FIRMWARE"

    if [ ! -d "$HOME/klipper" ]; then
        log_error "Klipper is not installed!"
        echo "  You need to install Klipper first via Quick Start [1]."
        echo ""
        read -p "  Press Enter..."
        return
    fi

    cd ~/klipper

    echo "  Step 1: Configure"
    echo "  ---------------------------------------------------"
    echo "  Select your MCU type and settings in menuconfig."
    echo ""
    read -p "  Press Enter to open menuconfig..."

    if ! make menuconfig; then
        log_error "Menuconfig cancelled or failed."
        read -p "  Press Enter..."
        return
    fi

    echo ""
    echo "  Step 2: Build"
    echo "  ---------------------------------------------------"
    log_info "Cleaning old build..."
    make clean > /dev/null

    log_info "Compiling (make -j$(nproc))..."
    if make -j$(nproc); then
        log_success "Firmware compiled!"
    else
        log_error "Build failed."
        read -p "  Press Enter..."
        return
    fi

    echo ""
    echo "  Step 3: Flash"
    echo "  ---------------------------------------------------"

    # === ARTIFACT-BASED FLASH DETECTION ===
    if [ -f "out/klipper.uf2" ]; then
        flash_rp2040
    elif [ -f "out/klipper.bin" ]; then
        flash_bin_artifact
    elif [ -f "out/klipper.elf.hex" ]; then
        flash_avr_artifact
    else
        log_error "No known firmware artifact found in out/"
        echo "  Expected: klipper.bin, klipper.uf2, or klipper.elf.hex"
        ls -la out/ 2>/dev/null
    fi

    read -p "  Press Enter to finish..."
}

# === LINUX HOST MCU (Fully Automatic) ===

function run_linux_wizard() {
    draw_header "LINUX HOST MCU"

    if [ ! -d "$HOME/klipper" ]; then
        log_error "Klipper is not installed!"
        echo "  You need to install Klipper first via Quick Start [1]."
        echo ""
        read -p "  Press Enter..."
        return
    fi

    echo "  This will compile & install Klipper for the Raspberry Pi itself."
    echo "  No configuration needed - fully automatic."
    echo ""
    read -p "  Start? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi

    cd ~/klipper

    # Auto-configure for Linux Process
    echo "CONFIG_LOW_LEVEL_OPTIONS=y" > .config
    echo "CONFIG_MACH_LINUX=y" >> .config

    make olddefconfig
    make clean > /dev/null

    log_info "Compiling..."
    if make -j$(nproc); then
        log_success "Build complete!"
    else
        log_error "Build failed."
        read -p "  Press Enter..."
        return
    fi

    log_info "Installing..."
    if make flash; then
        log_success "Installed!"

        # Ensure service is set up
        if [ ! -f "/etc/systemd/system/klipper-mcu.service" ]; then
            log_info "Registering klipper-mcu service..."
            sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/
            sudo systemctl enable klipper-mcu.service
            sudo systemctl daemon-reload
        fi

        sudo systemctl restart klipper-mcu.service
        log_success "Service klipper-mcu running."
    else
        log_error "Installation failed."
    fi
    read -p "  Press Enter..."
}

# === FLASH METHODS (Auto-Selected by Artifact) ===

function flash_rp2040() {
    echo ""
    echo "  ${C_GREEN}Detected: RP2040 (UF2)${NC}"
    echo "  ---------------------------------------------------"
    echo "  1. Hold BOOTSEL button on the board"
    echo "  2. Connect USB (or tap RESET while holding BOOTSEL)"
    echo "  3. A USB drive named 'RPI-RP2' should appear"
    echo ""

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
            cp out/klipper.uf2 "$rp2_mount/" && log_success "Firmware copied! Board will reboot."
        fi
    else
        echo "  ${C_YELLOW}RP2040 not detected as USB drive.${NC}"
        echo "  Put board in BOOTSEL mode and try again,"
        echo "  or manually copy: out/klipper.uf2 → RPI-RP2 drive"
    fi
}

function flash_bin_artifact() {
    echo ""
    echo "  ${C_GREEN}Detected: .bin firmware${NC}"
    echo "  ---------------------------------------------------"

    # Check for DFU device
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
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
    else
        echo "  No DFU device detected."
        echo ""
        echo "  [1] Flash via make flash (USB)"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
    fi

    echo ""
    read -p "  >> METHOD: " method

    case $method in
        1)
            log_info "Flashing..."
            echo "  Ensure device is in bootloader/DFU mode!"
            read -p "  Press Enter when ready..."
            make flash
            ;;
        2)
            echo ""
            echo "  SD CARD INSTRUCTIONS:"
            echo "  1. Firmware is at: ~/klipper/out/klipper.bin"
            echo "  2. Download via SCP to your computer"
            echo "  3. Rename to 'firmware.bin' (check your board docs)"
            echo "  4. Copy to FAT32 SD card"
            echo "  5. Insert into board, power cycle"
            echo ""
            echo "  ${C_YELLOW}[!] Some boards need a unique filename each flash.${NC}"
            ;;
        3) flash_via_can ;;
        [sS]) return ;;
    esac
}

function flash_avr_artifact() {
    echo ""
    echo "  ${C_GREEN}Detected: AVR (hex)${NC}"
    echo "  ---------------------------------------------------"
    echo "  Ensure board is connected via USB."
    read -p "  Press Enter to flash..."
    make flash
}

function flash_via_can() {
    echo ""
    log_info "CAN Bus Flashing (Katapult)"
    echo "  ---------------------------------------------------"

    if command -v candump &> /dev/null && ip link show can0 &> /dev/null; then
        echo "  CAN0 interface found."
    else
        log_warn "CAN interface not detected. Ensure can0 is configured."
    fi

    read -p "  Enter UUID to flash: " uuid
    if [ -z "$uuid" ]; then
        log_error "No UUID provided."
        return
    fi

    if [ -f "$HOME/katapult/scripts/flashtool.py" ]; then
        python3 "$HOME/katapult/scripts/flashtool.py" -u "$uuid"
    elif [ -f "$HOME/klipper/lib/canboot/flash_can.py" ]; then
        python3 "$HOME/klipper/lib/canboot/flash_can.py" -u "$uuid"
    else
        log_error "Could not find flash tool. Install Katapult first."
    fi
}

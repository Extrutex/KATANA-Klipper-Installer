#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE FORGE (Flash Engine)
# Usage: Firmware Build & Flash
# Rule: Flash method is determined by build artifact, NOT user choice
# ==============================================================================

function run_hal_flasher() {
    while true; do
        draw_header "🔧 THE FORGE - Build & Flash Firmware"
        echo ""
        echo "  ${C_GREEN}[1]${NC}  Build & Flash Firmware     (opens menuconfig)"
        echo "  ${C_NEON}[2]${NC}  Linux Host MCU             (automatic, no config needed)"
        echo "  ${C_NEON}[3]${NC}  Katapult (CanBoot) Manager"
        echo "  ${C_NEON}[4]${NC}  Update All Saved MCUs"
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
            4) run_mcu_update_all ;;
            b|B) return ;;
        esac
    done
}

# ... (existing functions) ...

# === MCU BATCH UPDATE ===

function run_mcu_update_all() {
    draw_header "BATCH UPDATE SAVED MCUS"
    
    if [ ! -d "$BOARD_REGISTRY_DIR" ]; then
        log_error "No saved boards found. Build and save one first!"
        read -p "  Press Enter..."
        return
    fi
    
    local configs=("$BOARD_REGISTRY_DIR"/*.meta)
    if [ ! -e "${configs[0]}" ]; then
        log_error "No saved boards found."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Found saved boards:"
    for meta in "${configs[@]}"; do
        source "$meta"
        echo "  - $BOARD_NAME ($ARCH)"
    done
    
    echo ""
    read -p "  Update all these boards now? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    for meta in "${configs[@]}"; do
        source "$meta"
        local config_file="$BOARD_REGISTRY_DIR/${BOARD_NAME}.config"
        
        draw_header "UPDATING: $BOARD_NAME"
        log_info "Architecture: $ARCH"
        
        if [ ! -f "$config_file" ]; then
            log_error "Config file missing for $BOARD_NAME"
            continue
        fi
        
        # 1. Restore Config
        cp "$config_file" "$HOME/klipper/.config"
        cd "$HOME/klipper" || return
        
        # 2. Build
        log_info "Building firmware..."
        make olddefconfig > /dev/null
        make clean > /dev/null
        if make -j$(nproc); then
            log_success "Build complete."
        else
            log_error "Build failed for $BOARD_NAME"
            continue
        fi
        
        # 3. Flash
        log_info "Flashing ($FLASH_METHOD)..."
        
        case $FLASH_METHOD in
            can)
                flash_via_can
                ;;
            manual)
                echo "  Skipping flash (Method: Manual/SD). Build is in out/."
                ;;
            usb|*)
                # USB Default
                if [ -f "out/klipper.uf2" ]; then flash_rp2040
                elif [ -f "out/klipper.bin" ]; then flash_bin_artifact
                elif [ -f "out/klipper.elf.hex" ]; then flash_avr_artifact
                fi
                ;;
        esac
        
        echo ""
        log_success "$BOARD_NAME finished."
        sleep 2
    done
    
    draw_success "All boards processed!"
    read -p "  Press Enter..."
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

    cd ~/klipper || { log_error "Klipper directory not found"; return 1; }

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
    echo "  Step 3: Post-Build Actions"
    echo "  ---------------------------------------------------"
    
    # Save Config Prompt
    read -p "  Save this configuration for later use? [y/N]: " save_yn
    if [[ "$save_yn" =~ ^[yY] ]]; then
        save_board_config
    fi

    echo ""
    echo "  Step 4: Flash"
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

# === BOARD REGISTRY (MCU Persistence) ===

BOARD_REGISTRY_DIR="$HOME/printer_data/config/katana_boards"

function save_board_config() {
    mkdir -p "$BOARD_REGISTRY_DIR"
    
    echo ""
    echo "  ${C_NEON}:: SAVE BOARD CONFIGURATION ::${NC}"
    echo "  Give this board a unique name (e.g. 'SHT36_Toolhead', 'U2C_Bridge')"
    read -p "  >> Name: " board_name
    
    # Sanitize name (alphanumeric + underscore only)
    board_name=$(echo "$board_name" | tr -cd '[:alnum:]_')
    
    if [ -z "$board_name" ]; then
        log_error "Invalid name. Config NOT saved."
        return
    fi
    
    local config_src="$HOME/klipper/.config"
    local config_dest="$BOARD_REGISTRY_DIR/${board_name}.config"
    local meta_dest="$BOARD_REGISTRY_DIR/${board_name}.meta"
    
    if [ -f "$config_src" ]; then
        cp "$config_src" "$config_dest"
        
        # Create Metadata
        echo "BOARD_NAME=\"$board_name\"" > "$meta_dest"
        echo "LAST_BUILT=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> "$meta_dest"
        
        # Extract Architecture from .config
        local arch="unknown"
        if grep -q "CONFIG_MACH_STM32=y" "$config_src"; then arch="stm32"; fi
        if grep -q "CONFIG_MACH_RP2040=y" "$config_src"; then arch="rp2040"; fi
        if grep -q "CONFIG_MACH_AVR=y" "$config_src"; then arch="avr"; fi
        if grep -q "CONFIG_MACH_LINUX=y" "$config_src"; then arch="linux"; fi
        echo "ARCH=\"$arch\"" >> "$meta_dest"
        
        echo ""
        echo "  How is this board connected? (for auto-update)"
        echo "  [1] USB (DFU/Serial) - Standard"
        echo "  [2] CAN Bus (Katapult) - Bridge required"
        echo "  [3] SD Card / Manual"
        read -p "  >> Method: " f_method
        
        case $f_method in
            2) echo "FLASH_METHOD=\"can\"" >> "$meta_dest" ;;
            3) echo "FLASH_METHOD=\"manual\"" >> "$meta_dest" ;;
            *) echo "FLASH_METHOD=\"usb\"" >> "$meta_dest" ;;
        esac
        
        log_success "Saved: $board_name"
        echo "  Location: $config_dest"
    else
        log_error ".config not found! Build first."
    fi
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

    cd ~/klipper || { log_error "Klipper directory not found"; return 1; }

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

        # Setup systemd service
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
    echo ""

    # === USB DEVICE SCAN ===
    echo "  Scanning USB devices..."
    echo ""

    local dfu_found=0
    local serial_device=""
    local usb_devices=""

    # Check lsusb for STM32 DFU mode (0483:df11)
    if command -v lsusb &> /dev/null; then
        usb_devices=$(lsusb 2>/dev/null)

        if echo "$usb_devices" | grep -qi "0483:df11"; then
            dfu_found=1
            echo -e "  ${C_GREEN}●${NC} STM32 DFU Device detected (0483:df11)"
        fi

        # Check for Katapult/CanBoot bootloader (1d50:6177)
        if echo "$usb_devices" | grep -qi "1d50:6177"; then
            echo -e "  ${C_GREEN}●${NC} Katapult (CanBoot) bootloader detected (1d50:6177)"
        fi

        # Check for Klipper USB device (1d50:614e)
        if echo "$usb_devices" | grep -qi "1d50:614e"; then
            echo -e "  ${C_YELLOW}●${NC} Klipper USB device detected (already running firmware)"
        fi
    fi

    # Also check dfu-util for more detail
    if [ $dfu_found -eq 0 ] && command -v dfu-util &> /dev/null; then
        if dfu-util -l 2>/dev/null | grep -q "Found DFU"; then
            dfu_found=1
            echo -e "  ${C_GREEN}●${NC} DFU device detected via dfu-util"
        fi
    fi

    # Find serial devices (common MCU paths)
    for dev in /dev/serial/by-id/*; do
        if [ -e "$dev" ]; then
            serial_device="$dev"
            echo -e "  ${C_GREEN}●${NC} USB Serial: $(basename $dev)"
        fi
    done

    if [ $dfu_found -eq 0 ] && [ -z "$serial_device" ]; then
        echo -e "  ${C_YELLOW}○${NC} No MCU devices detected via USB"
    fi

    echo ""
    echo "  ---------------------------------------------------"

    # === FLASH METHOD SELECTION ===
    if [ $dfu_found -eq 1 ]; then
        echo -e "  ${C_GREEN}Recommended: DFU flash (device in bootloader mode)${NC}"
        echo ""
        echo "  [1] Flash via DFU (USB)          ${C_GREEN}← recommended${NC}"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
    elif [ -n "$serial_device" ]; then
        echo -e "  ${C_GREEN}Recommended: USB Serial flash${NC}"
        echo ""
        echo "  [1] Flash via USB Serial         ${C_GREEN}← recommended${NC}"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
    else
        echo "  No device auto-detected. Options:"
        echo ""
        echo "  [1] Flash via make flash (USB)"
        echo "  [2] SD Card (manual copy)"
        echo "  [3] CAN Bus (Katapult)"
        echo "  [S] Skip"
        echo ""
        echo "  ${C_YELLOW}TIP: Set boot jumper, connect USB, then try [1]${NC}"
    fi

    echo ""
    read -p "  >> METHOD: " method

    case $method in
        1)
            if [ $dfu_found -eq 1 ]; then
                log_info "Flashing via DFU..."
                local flash_output
                flash_output=$(make flash FLASH_DEVICE=0483:df11 2>&1)
                local flash_exit=$?
                echo "$flash_output"
                
                if echo "$flash_output" | grep -q "File downloaded successfully"; then
                    echo ""
                    log_success "Firmware flashed successfully!"
                    echo "  (dfu-util detach warnings are normal and can be ignored)"
                    echo ""
                    echo "  ${C_NEON}Next steps:${NC}"
                    echo "  1. Remove BOOT jumper"
                    echo "  2. Press RESET button (or power cycle)"
                    echo "  3. Board will boot with new firmware"
                elif [ $flash_exit -ne 0 ]; then
                    log_error "Flash failed. Check USB connection."
                else
                    log_success "Flash complete!"
                fi
            elif [ -n "$serial_device" ]; then
                log_info "Flashing via USB Serial: $serial_device"
                if make flash FLASH_DEVICE="$serial_device"; then
                    log_success "Flash complete!"
                else
                    log_error "Flash failed."
                fi
            else
                log_info "Flashing..."
                echo "  Ensure device is in bootloader/DFU mode!"
                read -p "  Press Enter when ready..."
                make flash
            fi
            ;;
        2)
            echo ""
            echo "  SD CARD INSTRUCTIONS:"
            echo "  1. Firmware is at: ~/klipper/out/klipper.bin"
            echo "  2. Rename to 'firmware.bin' (check your board docs)"
            echo "  3. Copy to FAT32 formatted SD card"
            echo "  4. Insert into board, power cycle"
            echo ""
            echo "  ${C_YELLOW}[!] Some boards need a unique filename each flash.${NC}"
            echo ""
            echo "  Quick download via SCP:"
            echo "  scp $(whoami)@$(hostname -I | awk '{print $1}'):~/klipper/out/klipper.bin ."
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

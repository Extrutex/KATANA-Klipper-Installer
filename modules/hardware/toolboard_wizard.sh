#!/bin/bash
# ==============================================================================
# KATANA MODULE: TOOLBOARD WIZARD (Dr. Klipper Edition)
# Specialized Flashing for Toolboards (Nitehawk, SB2209, etc.)
# ==============================================================================

function run_toolboard_wizard() {
    while true; do
        draw_header "TOOLBOARD WIZARD"
        echo "  Specialized Flashing for CanBus Toolboards."
        echo ""
        echo "  [1] LDO Nitehawk 36/42 (RP2040) - USB ONLY (Not CAN Flashing)"
        echo "  [2] BTT SB2209 / EBB36 (STM32G0B1) - DFU Mode"
        echo "  [3] Mellow Fly-SHT (STM32F072) - DFU Mode"
        echo ""
        echo "  [B] Back"
        
        read -p "  >> SELECT BOARD: " board
        case $board in
            1) flash_nitehawk_rp2040 ;;
            2) flash_sb2209_stm32g0 ;;
            3) flash_generic_stm32f0 ;;
            b|B) return ;;
        esac
    done
}

function flash_nitehawk_rp2040() {
    draw_header "FLASH: LDO NITEHAWK (RP2040)"
    echo "  1. Put Nitehawk in Bootloader Mode:"
    echo "     - Hold BOOT button."
    echo "     - Press/Release RESET."
    echo "     - Release BOOT."
    echo "  2. Connect via USB."
    echo "  3. Wait for 'RPI-RP2' drive to appear."
    echo ""
    read -p "  Press Enter when ready..."
    
    cd ~/klipper || return
    
    # Check for compiled UF2
    if [ ! -f "out/klipper.uf2" ]; then
        log_error "klipper.uf2 not found! Please BUILD for RP2040 first."
        return
    fi
    
    log_info "Searching for RPI-RP2 volume..."
    
    # Try to find the mount point
    # On headless Pi, it might not auto-mount to /media. 
    # Check sda1/sdb1 etc.
    
    local mount_point=""
    for dev in /dev/sd*[1-9]; do
        if sudo blkid "$dev" | grep -q "RPI-RP2"; then
             log_success "Found RP2040 at $dev"
             
             # Mount it
             sudo mkdir -p /mnt/pico
             sudo mount "$dev" /mnt/pico
             mount_point="/mnt/pico"
             break
        fi
    done
    
    if [ -n "$mount_point" ]; then
        log_info "Flashing (Copying UF2)..."
        sudo cp out/klipper.uf2 "$mount_point/"
        sudo sync
        sudo umount "$mount_point"
        log_success "Flash Complete! Nitehawk should restart."
    else
        log_warn "RPI-RP2 drive not found."
        echo "  Alternative: 'make flash' (requires libusb rule)"
        read -p "  Try 'make flash'? [y/N]: " yn
        if [[ "$yn" =~ ^[yY] ]]; then
            make flash FLASH_DEVICE=2e8a:0003
        fi
    fi
    read -p "  Press Enter..."
}

function flash_sb2209_stm32g0() {
    draw_header "FLASH: SB2209 / EBB36 (STM32G0)"
    echo "  1. Put Board in DFU Mode (BOOT0 + RESET)"
    echo "  2. Connect via USB."
    echo ""
    read -p "  Press Enter when ready..."
    
    cd ~/klipper || return

    if [ ! -f "out/klipper.bin" ]; then
        log_error "klipper.bin not found! Build for STM32G0B1 first."
        return
    fi

    # Check for STM32 DFU
    if lsusb | grep -i "0483:df11"; then
        log_success "STM32 DFU Detected!"
    else
        log_warn "Device not found via lsusb. Assuming DFU is active anyway..."
    fi

    echo "  [i] Flashing address 0x08000000..."
    
    # Chip erase for G0B1
    sudo dfu-util -a 0 -s 0x08000000:leave -D out/klipper.bin
    
    if [ $? -eq 0 ]; then
        log_success "Flash Successful!"
    else
        log_error "Flash Failed. Check cable or boot jumper."
    fi
    
    read -p "  Press Enter..."
}

function flash_generic_stm32f0() {
    draw_header "FLASH: GENERIC STM32F0"
    cd ~/klipper || return
     sudo dfu-util -a 0 -s 0x08000000:leave -D out/klipper.bin
    read -p "  Press Enter..."
}

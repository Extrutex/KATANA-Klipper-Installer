#!/bin/bash

# --- THE FORGE: MCU FLASHING & DETECTION ---

function run_flash_menu() {
    while true; do
        draw_header "THE FORGE PRO - MCU MANAGER"
        echo "  1) Detect MCUs (USB & CAN)"
        echo "  2) Build & Flash Firmware (Klipper)"
        echo "  3) Setup CAN-Bus Network (Katapult/CanBoot)"
        echo "  B) Back"
        read -p "  >> " ch

        case $ch in
            1) detect_mcus ;;
            2) build_and_flash ;;
            3) setup_can_network ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function detect_mcus() {
    log_info "Scanning USB Bus..."
    local usb_devs=$(ls /dev/serial/by-id/* 2>/dev/null)
    
    if [ -z "$usb_devs" ]; then
        echo "  [warn] No USB Serial devices found."
    else
        echo "  [+] USB Devices Found:"
        echo "$usb_devs"
    fi
    
    log_info "Scanning CAN Bus (uuid)..."
    # Check if katapult/scripts/flashtool.py exists or use python script
    # Providing a simple python one-liner to query canbus uuids (requires Klipper/Katapult env)
    
    if [ -f "$HOME/klipper/lib/canboot/flash_can.py" ]; then
         # Using Klipper's CAN query if available (or custom script)
         # For now, let's just list network interfaces
         ip -br link show can0 2>/dev/null || echo "  [warn] Interface can0 not up."
    fi
    
    read -p "  Press Enter..."
}

function build_and_flash() {
    log_info "Entering Klipper Build System..."
    
    # 1. Check Klipper Dir
    local klipper_dir="$HOME/klipper"
    if [ ! -d "$klipper_dir" ]; then
        log_error "Klipper not found at $klipper_dir"
        return
    fi
    
    # 2. Menuconfig
    cd "$klipper_dir"
    log_info "Running make menuconfig..."
    make menuconfig
    
    # 3. Clean & Make
    log_info "Building Firmware..."
    make
    
    if [ $? -eq 0 ]; then
        log_success "Build Successful!"
        
        # 4. Flash Strategy
        echo ""
        echo "  Flash Method:"
        echo "  1) USB (dfu-util / avrdude)"
        echo "  2) SD Card (Copy klipper.bin)"
        echo "  3) CAN-Bus (Katapult)"
        read -p "  >> " method
        
        case $method in
            1) 
                log_info "Flashing via USB..."
                # Find device first? or let make flash handle it?
                # Best practice: make flash FLASH_DEVICE=...
                # For now, simple make flash for standard boards
                make flash
                ;;
            2)
                log_info "Output: $klipper_dir/out/klipper.bin"
                log_info "Copy this file to your SD Card and rename to 'firmware.bin' (usually)."
                ;;
            3)
                read -p "  Enter CAN UUID: " uuid
                python3 lib/canboot/flash_can.py -u $uuid
                ;;
        esac
    else
        log_error "Build failed."
    fi
    read -p "  Press Enter..."
}

function setup_can_network() {
    log_info "Setting up CAN0 Interface..."
    
    # 1. Ask for Bitrate
    echo "  Target Bitrate:"
    echo "  1) 500000 (500k)"
    echo "  2) 1000000 (1M)"
    read -p "  >> " br_sel
    local bitrate="500000"
    if [ "$br_sel" == "2" ]; then bitrate="1000000"; fi
    
    # 2. Create Interface File
    local net_file="/etc/network/interfaces.d/can0"
    
    echo "  [i] Creating $net_file with bitrate $bitrate..."
    
    # Safety Check: Sudo
    if ! sudo -n true 2>/dev/null; then
        echo "  [!] Sudo required."
    fi
    
    sudo tee "$net_file" > /dev/null <<EOF
allow-hotplug can0
iface can0 can static
    bitrate $bitrate
    up ifconfig \$IFACE txqueuelen 128
EOF
    
    log_success "Interface file created."
    log_info "Restarting Networking..."
    # Warning: This might disconnect SSH if not careful, but usually safe for interfaces.d
    # Better: specifically up can0
    sudo ifup can0 2>/dev/null || sudo ip link set can0 up type can bitrate $bitrate
    
    log_success "CAN0 Setup Attempted."
    ip -br link show can0
    read -p "  Press Enter..."
}

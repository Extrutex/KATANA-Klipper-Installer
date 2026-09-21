#!/bin/bash
# ==============================================================================
# KATANA MODULE: KATAPULT MANAGER (Bootloader)
# Handles the installation and flashing of the Katapult (CanBoot) bootloader.
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$KATANA_ROOT/core/logger.sh"
fi

KATAPULT_DIR="$HOME/katapult"

function run_katapult_menu() {
    while true; do
        draw_header "KATAPULT (CAN BOOTLOADER)"
        echo "  Manage the Bootloader for your CAN nodes."
        echo ""
        echo "  [1] Install/Update Katapult (Git Clone)"
        echo "  [2] Configure & Build Bootloader"
        echo "  [3] Flash Bootloader to MCU (via DFU)"
        echo ""
        echo "  [B] Back"
        
        katana_read_menu ch "  >> SELECT: " "KATAPULT MANAGER" || return
        case $ch in
            1) install_katapult_repo ;;
            2) build_katapult ;;
            3) flash_katapult_dfu ;;
            b|B) return ;;
        esac
    done
}

function install_katapult_repo() {
    log_info "Downloading Katapult..."
    if [ -d "$KATAPULT_DIR" ]; then
        cd "$KATAPULT_DIR" || return 1
        git pull
    else
        git clone https://github.com/Arksine/katapult "$KATAPULT_DIR"
    fi
    log_success "Katapult repository ready."
    
    # Install dependencies (pip)
    log_info "Checking dependencies..."
    if ! pip3 show pyserial >/dev/null 2>&1; then
        pip3 install pyserial
    fi
    katana_pause "  Press Enter..."
}

function build_katapult() {
    if [ ! -d "$KATAPULT_DIR" ]; then
        log_error "Katapult not installed. Run Step 1 first."
        return 1
    fi
    cd "$KATAPULT_DIR" || { log_error "Katapult directory not found"; return 1; }
    
    draw_header "BUILD KATAPULT"
    echo "  Select your architecture in menuconfig."
    katana_pause "  Press Enter to configure..."
    
    make menuconfig
    make clean
    
    log_info "Building..."
    if make; then
        log_success "Bootloader built: out/katapult.bin (or .uf2)"
        save_workflow_state "KATAPULT_BUILT" "$(basename "$PWD")" "Bootloader kompiliert, bereit zum Flashen"
    else
        log_error "Build failed."
    fi
    katana_pause "  Press Enter..."
}

function flash_katapult_dfu() {
    draw_header "FLASH KATAPULT (DFU)"
    echo "  Ensure your device is in DFU Mode!"
    echo "  (Press Boot button + Reset)"
    echo ""
    katana_pause "  Press Enter when ready..."
    
    cd "$KATAPULT_DIR" || return 1

    # The pause above ("Press Enter when ready") is not consent — it returns 0
    # unconditionally by contract, so unattended this function walked straight
    # into `make flash` and overwrote the bootloader of whatever board happened
    # to be in DFU mode. This is the gate.
    if ! katana_confirm_destructive "  Katapult-Bootloader jetzt flashen? [y/N]: " flash; then
        log_info "Flash abgebrochen — Board unveraendert."
        return 1
    fi

    log_info "Flashing via DFU..."
    if make flash; then
        log_success "Katapult geflasht!"
        save_workflow_state "KATAPULT_FLASHED" "$(basename "$PWD")" "Bootloader geflasht. Nächster Schritt: Klipper bauen & flashen."
        echo ""
        echo "  ${C_GREEN}>>> Nächster Schritt: Gehe zu FORGE → [1] Build New Firmware${NC}"
        echo "  ${C_GREEN}>>> um Klipper auf dieses Board zu flashen.${NC}"
    else
        log_warn "Flash möglicherweise fehlgeschlagen. Device-ID prüfen."
    fi
    katana_pause "  Press Enter..."
}

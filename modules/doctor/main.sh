#!/bin/bash
# ==============================================================================
# KATANA DOCTOR - DIAGNOSTIC & REPAIR MODULE
# ==============================================================================

function run_katana_doctor() {
    while true; do
        clear
        draw_top
        print_box_line " ${C_TXT}KATANA DOCTOR // SYSTEM DIAGNOSTICS${NC}"
        draw_line
        print_box_line " ${C_GREY}Diagnose and automatically fix common issues.${NC}"
        draw_line
        
        # Menu Options
        menu_item "1" "PERMISSION FIXER" "Repair ~/printer_data ownership"
        menu_item "2" "DEPENDENCY CHECK" "Verify system packages"
        menu_item "3" "SERVICE HEALTH" "Analyze Klipper service status"
        draw_line
        menu_item "B" "BACK" "Return to Main Menu"
        draw_bot

        read -p "  >> SELECT DIAGNOSTIC: " doc_choice
        case $doc_choice in
            1) doctor_check_permissions ;;
            2) doctor_check_dependencies ;;
            3) doctor_check_service ;;
            [bB]) return ;;
            *) log_error "Invalid option selected." ;;
        esac
    done
}

# --- 1. PERMISSION FIXER ---
function doctor_check_permissions() {
    clear
    draw_top
    print_box_line " ${C_TXT}PERMISSION FIXER${NC}"
    draw_line
    
    local target_dir="$HOME/printer_data"
    log_info "Scanning $target_dir for ownership issues..."
    
    # Check if any file is NOT owned by pi:pi
    if find "$target_dir" ! -user pi -o ! -group pi -print -quit | grep -q .; then
        log_warn "Ownership issues detected!"
        echo -e "Some files in ${target_dir} are not owned by user 'pi'."
        
        read -p "  >> Fix permissions (sudo chown -R pi:pi)? [y/N]: " fix_perm
        if [[ "$fix_perm" =~ [yY] ]]; then
            log_info "Fixing permissions..."
            if sudo chown -R pi:pi "$target_dir"; then
                log_success "Permissions fixed successfully."
            else
                log_error "Failed to fix permissions."
            fi
        else
            log_info "Skipping fix."
        fi
    else
        log_success "All files in $target_dir are correctly owned by pi:pi."
    fi
    read -p "Press Enter to continue..."
}

# --- 2. DEPENDENCY CHECK ---
function doctor_check_dependencies() {
    clear
    draw_top
    print_box_line " ${C_TXT}DEPENDENCY CHECK${NC}"
    draw_line

    local required_pkgs=("python3-numpy" "libopenjp2-7" "python3-matplotlib" "libatlas-base-dev")
    local missing_pkgs=()

    for pkg in "${required_pkgs[@]}"; do
        if dpkg -s "$pkg" &> /dev/null; then
             echo -e "  [${C_GREEN}OK${NC}] $pkg"
        else
             echo -e "  [${C_RED}MISSING${NC}] $pkg"
             missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo ""
        log_warn "Found ${#missing_pkgs[@]} missing/broken packages."
        read -p "  >> Attempt to install/reinstall missing packages? [y/N]: " fix_deps
        if [[ "$fix_deps" =~ [yY] ]]; then
            log_info "Installing missing packages..."
            sudo apt-get update
            if sudo apt-get install --reinstall -y "${missing_pkgs[@]}"; then
                log_success "Dependencies installed successfully."
            else
                log_error "Failed to install some packages."
            fi
        fi
    else
        echo ""
        log_success "All core dependencies seem intact."
    fi
    read -p "Press Enter to continue..."
}

# --- 3. SERVICE HEALTH ---
function doctor_check_service() {
    clear
    draw_top
    print_box_line " ${C_TXT}SERVICE HEALTH CHECK${NC}"
    draw_line

    echo -e "Checking Klipper service status..."
    if systemctl is-active --quiet klipper; then
        log_success "Klipper service is ACTIVE (Running)."
    else
        log_error "Klipper service is INACTIVE or FAILED."
        echo -e "Analyzing logs for potential causes..."
        
        # Capture last 50 lines of log
        local log_output
        log_output=$(journalctl -u klipper -n 50 --no-pager)
        
        # Simple heuristic analysis
        if echo "$log_output" | grep -q "mcu 'mcu': Unable to connect"; then
             echo -e "  -> ${C_RED}DIAGNOSIS: MCU Connection Failed${NC}"
             echo "     Check USB cable, serial port path in printer.cfg, or if MCU is flashed."
        elif echo "$log_output" | grep -q "Config error"; then
             echo -e "  -> ${C_RED}DIAGNOSIS: Configuration Error${NC}"
             echo "     Check your printer.cfg for syntax errors."
        elif echo "$log_output" | grep -q "ADC out of range"; then
             echo -e "  -> ${C_RED}DIAGNOSIS: Thermistor Issue${NC}"
             echo "     A temperature sensor is reporting impossible values (short/open circuit)."
        else
             echo -e "  -> ${C_WARN}DIAGNOSIS: Unknown Error${NC}"
             echo "     Please inspect 'journalctl -u klipper -xe' manually."
        fi
        
        echo ""
        echo "Recent Log Snippet:"
        echo "---------------------------------------------------"
        journalctl -u klipper -n 10 --no-pager
        echo "---------------------------------------------------"
    fi
    read -p "Press Enter to continue..."
}

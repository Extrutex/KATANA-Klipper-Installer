#!/bin/bash

function run_dr_katana() {
    draw_header "DR. KATANA - LOG DIAGNOSTICS"
    echo "  Scans your klippy.log for common failures."
    
    local log_file="$HOME/printer_data/logs/klippy.log"
    
    if [ ! -f "$log_file" ]; then
        log_error "No klippy.log found at $log_file"
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Analyzing $(basename $log_file)..."
    echo "  ----------------------------------------"
    
    # Analysis Logic
    local found_issues=0
    
    # 1. Timer too close
    if grep -q "Timer too close" "$log_file"; then
        echo -e "${C_RED}[!] MCU Shutdown: Timer too close${NC}"
        echo "    -> Possible Cause: RPi overloaded, poor USB cable, or SD card slow."
        found_issues=1
    fi
    
    # 2. ADC out of range
    if grep -q "ADC out of range" "$log_file"; then
        echo -e "${C_RED}[!] ADC out of range${NC}"
        echo "    -> Possible Cause: Thermistor broken, shorted, or loose wiring."
        found_issues=1
    fi
    
    # 3. Heater not heating
    if grep -q "Heater .* not heating at expected rate" "$log_file"; then
        echo -e "${C_RED}[!] Heater Fault${NC}"
        echo "    -> Possible Cause: Heater cartridge loose, PSU voltage drop, or fan blowing on block."
        found_issues=1
    fi
    
    # 4. No issues?
    if [ $found_issues -eq 0 ]; then
        log_success "No critical common errors found in recent logs."
        echo "    (That doesn't mean everything is perfect, but it looks healthy!)"
    fi
    
    echo ""
    echo "  [i] Full log handling coming in v2.1"
    read -p "  Press Enter..."
}

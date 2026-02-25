#!/bin/bash
# scripts/log_analyzer.sh
# Dr. KAANA - Klippy Log Analyzer

LOG_FILE="$HOME/printer_data/logs/klippy.log"

echo "  ------------------------------------"
echo "  🔍 DR. KATANA LOG ANALYSIS"
echo "  ------------------------------------"

if [ ! -f "$LOG_FILE" ]; then
    echo "  [!] No klippy.log found at $LOG_FILE"
    exit 1
fi

echo "  Target: $LOG_FILE"
echo "  Scanning for critical events..."
echo ""

# Helper to grep and count
function scan_event() {
    local pattern="$1"
    local label="$2"
    local count=$(grep -c "$pattern" "$LOG_FILE")
    
    if [ "$count" -gt 0 ]; then
        echo -e "  🔴 FOUND $count x '$label'"
        echo "     Last occurenc:"
        grep "$pattern" "$LOG_FILE" | tail -n 1 | cut -c 1-80
        echo ""
    else
        echo -e "  🟢 No '$label' events found."
    fi
}

scan_event "MCU '.*' shutdown" "MCU Shutdown"
scan_event "Timer too close" "Timer too close"
scan_event "Communication timeout" "Comm Timeout"
scan_event "ADC out of range" "Thermal Runaway / ADC Error"
scan_event "Heater .* not heating at expected rate" "Heater Verification Error"

echo "  ------------------------------------"
echo "  Scan Complete."

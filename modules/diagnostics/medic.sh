#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE MEDIC
# Deep System Diagnostics & Evidence Bag Creation
# ==============================================================================

function run_system_diagnostics() {
    draw_header "DR. KATANA - DEEP SCAN"
    echo "  Initiating system health check..."
    echo "  This will analyze services, storage, and power."
    echo ""

    local diag_dir="$HOME/katana_diagnostics"
    mkdir -p "$diag_dir"
    local timestamp=$(date +"%Y-%m-%d_%H-%M")
    local zip_name="katana_debug_${timestamp}.zip"
    local staging_dir
    staging_dir=$(mktemp -d)

    mkdir -p "$staging_dir"

    # 1. Vital Signs (Systemd)
    log_info "Checking System Services..."
    local failed_units=$(systemctl list-units --failed --no-legend --plain)
    if [ -n "$failed_units" ]; then
        log_error "Failed Services Detected!"
        echo "$failed_units" | tee "$staging_dir/failed_services.txt"
    else
        log_success "All services healthy."
        echo "All systems operational." > "$staging_dir/health_check.txt"
    fi

    # 2. Storage Check
    log_info "Checking Storage..."
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$disk_usage" -gt 85 ]; then
        log_warn "Disk critical: ${disk_usage}% used."
        echo "WARNING: Disk usage at ${disk_usage}%" >> "$staging_dir/health_check.txt"
    else
        log_success "Storage nominal (${disk_usage}%)."
    fi

    # 3. Power/Thermal (Raspberry Pi specific)
    if command -v vcgencmd >/dev/null 2>&1; then
        log_info "Checking Power/Thermal..."
        local throttled=$(vcgencmd get_throttled)
        echo "$throttled" >> "$staging_dir/power_report.txt"
        if [[ "$throttled" != "throttled=0x0" ]]; then
            log_warn "Power/Thermal throttling detected! ($throttled)"
        else
            log_success "Power stable."
        fi
    fi

    # 4. Evidence Collection
    log_info "Collecting logs & configs..."
    
    # Klippy Log
    if [ -f "$HOME/printer_data/logs/klippy.log" ]; then
        cp "$HOME/printer_data/logs/klippy.log" "$staging_dir/"
    fi
    
    # Moonraker Log
    if [ -f "$HOME/printer_data/logs/moonraker.log" ]; then
        cp "$HOME/printer_data/logs/moonraker.log" "$staging_dir/"
    fi
    
    # Configs
    if [ -d "$HOME/printer_data/config" ]; then
        cp "$HOME/printer_data/config/printer.cfg" "$staging_dir/" 2>/dev/null
        cp "$HOME/printer_data/config/moonraker.conf" "$staging_dir/" 2>/dev/null
        cp -r "$HOME/printer_data/config/macros" "$staging_dir/" 2>/dev/null
    fi

    # 5. Packaging
    log_info "Packaging diagnostics..."
    check_dependency "zip" "zip"
    
    cd /tmp
    zip -r -q "$diag_dir/$zip_name" "katana_debug_${timestamp}"
    rm -rf "$staging_dir"

    if [ $? -eq 0 ]; then
        log_success "Diagnostic Pack created!"
        echo "  [i] File: $diag_dir/$zip_name"
        echo "  [i] Send this file to the KATANA support channel."
    else
        log_error "Packaging failed."
    fi

    read -p "  Press [Enter] to return..."
}

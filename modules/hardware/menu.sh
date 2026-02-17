#!/bin/bash
# ==============================================================================
# KATANA MODULE: Hardware Menu Dispatcher
# Reference: 
# - StealthChanger: https://github.com/DraftShift/StealthChanger
# - MADMAX: https://github.com/zruncho3d/madmax
# - Cartographer: https://github.com/Cartographer3D
# - Beacon: https://github.com/beacon3d
# - BTT Eddy: https://github.com/bigtreetech/Eddy
# - Bed Distance Sensor: https://github.com/markniu/Bed_Distance_sensor
# ==============================================================================

function run_hardware_menu() {
    while true; do
        draw_header "🧩 HARDWARE EXTENSIONS"
        echo ""
        echo "  --- Toolchangers ---"
        echo "  [1] Happy Hare (MMU V1/V2/ERCF)"
        echo "  [2] StealthChanger"
        echo "  [3] MADMAX Toolchanger"
        echo ""
        echo "  --- Probes / Z-Sensors ---"
        echo "  [4] Smart Probe Menu"
        echo "  [5] Cartographer Probe"
        echo "  [6] Beacon Probe"
        echo "  [7] BTT Eddy Probe"
        echo "  [8] Bed Distance Sensor"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> SELECT: " ch
        
        case $ch in
            1) install_happy_hare ;;
            2) install_stealthchanger ;;
            3) install_madmax ;;
            4) 
                source "$MODULES_DIR/extras/smart_probes.sh"
                run_smartprobe_menu
                ;;
            5)
                source "$MODULES_DIR/extras/smart_probes.sh"
                install_cartographer
                ;;
            6)
                source "$MODULES_DIR/extras/smart_probes.sh"
                install_beacon
                ;;
            7)
                source "$MODULES_DIR/extras/smart_probes.sh"
                install_btt_eddy
                ;;
            8) install_bed_distance_sensor ;;
            [bB]) return ;;
            *) log_error "Invalid Selection." ;;
        esac
    done
}

# ============================================================
# STEALTHCHANGER (Reference: DraftShift/StealthChanger)
# ============================================================

function install_stealthchanger() {
    draw_header "STEALTHCHANGER"
    echo ""
    echo "  Reference: https://github.com/DraftShift/StealthChanger"
    echo ""
    echo "  StealthChanger is a toolchanging system for Voron printers."
    echo ""
    echo "  Features:"
    echo "  • Tool Docking"
    echo "  • Mechanical Tool Lock"
    echo "  • Toolhead Switching Workflow"
    echo ""
    read -p "  Install StealthChanger config? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local tc_dir="$cfg_dir/stealthchanger"
    
    mkdir -p "$tc_dir"
    
    # Create basic config based on StealthChanger docs
    cat > "$tc_dir/tool.cfg" << 'EOF'
# StealthChanger Basic Configuration
# Reference: https://github.com/DraftShift/StealthChanger

[gcode_macro TOOL_PARK]
description: Park current tool
gcode:
    {% set tool = printer.toolhead.extruder %}
    G90
    G0 Z10 F3000
    G0 X{printer.toolhead.axis_maximum.x - 20} Y{printer.toolhead.axis_maximum.y - 20} F6000

[gcode_macro PICK_TOOL]
description: Pick up tool T{n}
gcode:
    {% set t = params.T|default(0)|int %}
    G90
    G0 Z15 F3000
    ; Move to dock position (customize for your setup)
    G0 X300 Y300 F6000
    T{t}
    G0 Z0.5

[gcode_macro DROP_TOOL]
description: Drop current tool
gcode:
    G90
    G0 Z10 F3000
    ; Move to dock position (customize for your setup)
    G0 X300 Y300 F6000
    T-1
EOF

    # Add include to printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "stealthchanger" "$pcfg"; then
            echo "" >> "$pcfg"
            echo "# --- StealthChanger ---" >> "$pcfg"
            echo "[include stealthchanger/*.cfg]" >> "$pcfg"
        fi
    fi
    
    # Register for Moonraker Update Manager
    register_stealthchanger_updates
    
    draw_success "StealthChanger config created!"
    echo "  Location: $tc_dir/tool.cfg"
    echo "  [i] Customize dock positions for your setup!"
    read -p "  Press Enter..."
}

# ============================================================
# MADMAX TOOLCHANGER (Reference: zruncho3d/madmax)
# ============================================================

function install_madmax() {
    draw_header "MADMAX TOOLCHANGER"
    echo ""
    echo "  Reference: https://github.com/zruncho3d/madmax"
    echo ""
    echo "  MADMAX is a toolchanging system for Voron printers."
    echo ""
    echo "  Features:"
    echo "  • Mechanical Tool Lock"
    echo "  • Docking-Architektur"
    echo "  • Pickup / Dropoff Sequenzen"
    echo ""
    read -p "  Install MADMAX config? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local mm_dir="$cfg_dir/madmax"
    
    mkdir -p "$mm_dir"
    
    # Create basic config based on MADMAX docs
    cat > "$mm_dir/madmax.cfg" << 'EOF'
# MADMAX Toolchanger Configuration
# Reference: https://github.com/zruncho3d/madmax

[gcode_macro MC_HOME]
description: Home all axes
gcode:
    G28
    T-1

[gcode_macro MC_PRINT_START]
description: Print start sequence
gcode:
    T0
    G28
    ; Custom probe sequence

[gcode_macro MC_TOOL_CHANGE]
description: Tool change macro
gcode:
    {% set t = params.T|int %}
    SAVE_GCODE_STATE NAME=MC_TOOL_STATE
    ; Drop current tool
    G90
    G0 Z15 F3000
    ; Move to dock (customize)
    G0 X280 Y280 F6000
    T{t}
    ; Pickup new tool
    RESTORE_GCODE_STATE NAME=MC_TOOL_STATE
EOF

    # Add include to printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "madmax" "$pcfg"; then
            echo "" >> "$pcfg"
            echo "# --- MADMAX Toolchanger ---" >> "$pcfg"
            echo "[include madmax/*.cfg]" >> "$pcfg"
        fi
    fi
    
    # Register for Moonraker Update Manager
    register_madmax_updates
    
    draw_success "MADMAX config created!"
    echo "  Location: $mm_dir/madmax.cfg"
    echo "  [i] Customize dock positions for your setup!"
    read -p "  Press Enter..."
}

# ============================================================
# CARTOGRAPHER PROBE - Redirects to smart_probes.sh
# ============================================================
# Real implementation is in modules/extras/smart_probes.sh
# This module's install_cartographer has been removed to avoid
# installing fake [probe] configs with invented pin numbers.
# The smart_probes.sh version clones the official repo and runs
# the upstream install script.

# ============================================================
# BEACON PROBE - Redirects to smart_probes.sh
# ============================================================
# Real implementation is in modules/extras/smart_probes.sh

# ============================================================
# BTT EDDY PROBE - Redirects to smart_probes.sh
# ============================================================
# Real implementation is in modules/extras/smart_probes.sh

# ============================================================
# BED DISTANCE SENSOR (Reference: markniu/Bed_Distance_sensor)
# ============================================================

function install_bed_distance_sensor() {
    draw_header "BED DISTANCE SENSOR"
    echo ""
    echo "  Reference: https://github.com/markniu/Bed_Distance_sensor"
    echo ""
    echo "  The Bed Distance Sensor (BDS) is an accelerometer-based"
    echo "  probe for automatic Z-offset calibration."
    echo ""
    echo "  Features:"
    echo "  • Accelerometer-based Z probing"
    echo "  • Automatic mesh generation"
    echo "  • No physical probe required"
    echo ""
    read -p "  Install Bed Distance Sensor? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local bds_dir="$cfg_dir/bed_distance_sensor"
    
    mkdir -p "$bds_dir"
    
    # Clone repository
    if [ ! -d "$HOME/bed_distance_sensor" ]; then
        log_info "Cloning Bed Distance Sensor..."
        cd "$HOME"
        git clone https://github.com/markniu/Bed_Distance_sensor.git
    fi
    
    # Copy config
    cp "$HOME/bed_distance_sensor/klipper_config/BDS.cfg" "$bds_dir/" 2>/dev/null || \
    cat > "$bds_dir/bds.cfg" << 'EOF'
# Bed Distance Sensor Configuration
# Reference: https://github.com/markniu/Bed_Distance_sensor

[bds_sensor]
# Adjust pin to your setup
pin: PB1
# x_offset: 0
# y_offset: 0

[gcode_macro BDS_CALIBRATE]
description: Calibrate BDS sensor
gcode:
    BDS_CALIBRATE

[gcode_macro BDS_PROBE]
description: Probe with BDS sensor
gcode:
    BDS_PROBE
EOF

    # Add include to printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "bed_distance_sensor" "$pcfg"; then
            echo "" >> "$pcfg"
            echo "# --- Bed Distance Sensor ---" >> "$pcfg"
            echo "[include bed_distance_sensor/*.cfg]" >> "$pcfg"
        fi
    fi
    
    # Register for Moonraker Update Manager
    register_bed_distance_sensor_updates
    
    draw_success "Bed Distance Sensor installed!"
    echo "  Location: $bds_dir/"
    echo "  [i] Adjust pin for your setup!"
    echo "  [i] Requires ADXL345 accelerometer connected!"
    read -p "  Press Enter..."
}

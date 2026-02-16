#!/bin/bash
# ==============================================================================
# KATANA MODULE: Hardware Menu Dispatcher
# Reference: 
# - StealthChanger: https://github.com/DraftShift/StealthChanger
# - MADMAX: https://github.com/zruncho3d/madmax
# - Cartographer: https://github.com/Cartographer3D
# - Beacon: https://github.com/beacon3d
# - BTT Eddy: https://github.com/bigtreetech/Eddy
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
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> SELECT: " ch
        
        case $ch in
            1) install_happy_hare ;;
            2) install_stealthchanger ;;
            3) install_madmax ;;
            4) install_smart_probe ;;
            5) install_cartographer ;;
            6) install_beacon ;;
            7) install_btt_eddy ;;
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
    
    draw_success "MADMAX config created!"
    echo "  Location: $mm_dir/madmax.cfg"
    echo "  [i] Customize dock positions for your setup!"
    read -p "  Press Enter..."
}

# ============================================================
# CARTOGRAPHER PROBE (Reference: Cartographer3D)
# ============================================================

function install_cartographer() {
    draw_header "CARTOGRAPHER PROBE"
    echo ""
    echo "  Reference: https://github.com/Cartographer3D"
    echo ""
    echo "  Cartographer is an inductive/ eddy-based Z-probe."
    echo ""
    echo "  Features:"
    echo "  • High-speed meshing"
    echo "  • Induktive / Eddy-basierte Z-Messung"
    echo "  • Sensor-Kalibrierung"
    echo ""
    read -p "  Install Cartographer config? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local probe_dir="$cfg_dir/cartographer"
    
    mkdir -p "$probe_dir"
    
    # Create Cartographer config
    cat > "$probe_dir/cartographer.cfg" << 'EOF'
# Cartographer Probe Configuration
# Reference: https://github.com/Cartographer3D

[probe]
pin: PG12
x_offset: 0
y_offset: 0
z_offset: 0
speed: 10
samples: 2
sample_retract_dist: 3
samples_tolerance: 0.006
samples_tolerance_retries: 3

[safe_z_home]
home_xy_position: 150,150
z_hop: 10
z_hop_speed: 5

[bed_mesh]
speed: 50
horizontal_move_z: 5
mesh_min: 20,20
mesh_max: 280,280
probe_count: 5,5
algorithm: bidirectional
bicubic_tension: 0.2
EOF

    # Add include to printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "cartographer" "$pcfg"; then
            echo "" >> "$pcfg"
            echo "# --- Cartographer Probe ---" >> "$pcfg"
            echo "[include cartographer/*.cfg]" >> "$pcfg"
        fi
    fi
    
    draw_success "Cartographer config created!"
    echo "  Location: $probe_dir/cartographer.cfg"
    echo "  [i] Adjust pin, offsets, and mesh size for your setup!"
    read -p "  Press Enter..."
}

# ============================================================
# BEACON PROBE (Reference: beacon3d)
# ============================================================

function install_beacon() {
    draw_header "BEACON PROBE"
    echo ""
    echo "  Reference: https://github.com/beacon3d"
    echo ""
    echo "  Beacon is an Eddy Current Probe for high-precision Z-mapping."
    echo ""
    echo "  Features:"
    echo "  • Echtzeit Z-Mapping"
    echo "  • Eddy Current Technology"
    echo "  • Mesh-Integration mit Klipper"
    echo ""
    read -p "  Install Beacon config? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local beacon_dir="$cfg_dir/beacon"
    
    mkdir -p "$beacon_dir"
    
    # Create Beacon config
    cat > "$beacon_dir/beacon.cfg" << 'EOF'
# Beacon Probe Configuration
# Reference: https://github.com/beacon3d

[probe]
pin: PA4
x_offset: 0
y_offset: 0
z_offset: 0
speed: 20
samples: 3
sample_retract_dist: 2

[bed_mesh]
speed: 100
horizontal_move_z: 5
mesh_min: 25,25
mesh_max: 275,275
probe_count: 7,7
algorithm: bidirectional
EOF

    # Add include to printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "beacon" "$pcfg"; then
            echo "" >> "$pcfg"
            echo "# --- Beacon Probe ---" >> "$pcfg"
            echo "[include beacon/*.cfg]" >> "$pcfg"
        fi
    fi
    
    draw_success "Beacon config created!"
    echo "  Location: $beacon_dir/beacon.cfg"
    echo "  [i] Adjust pin and mesh size for your setup!"
    read -p "  Press Enter..."
}

# ============================================================
# BTT EDDY PROBE (Reference: bigtreetech/Eddy)
# ============================================================

function install_btt_eddy() {
    draw_header "BTT EDDY PROBE"
    echo ""
    echo "  Reference: https://github.com/bigtreetech/Eddy"
    echo ""
    echo "  BTT Eddy is an Eddy Current Probe from BigTreeTech."
    echo ""
    echo "  Features:"
    echo "  • Eddy Current Probe Implementation"
    echo "  • Sensor Firmware"
    echo "  • Klipper Integration"
    echo ""
    read -p "  Install BTT Eddy config? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local eddy_dir="$cfg_dir/btt_eddy"
    
    mkdir -p "$eddy_dir"
    
    # Create BTT Eddy config
    cat > "$eddy_dir/eddy.cfg" << 'EOF'
# BTT Eddy Probe Configuration
# Reference: https://github.com/bigtreetech/Eddy

[probe]
pin: PC14
x_offset: 0
y_offset: 0
z_offset: 0
speed: 15
samples: 3
sample_retract_dist: 3

[bed_mesh]
speed: 50
horizontal_move_z: 5
mesh_min: 20,20
mesh_max: 280,280
probe_count: 5,5
algorithm: bidirectional
EOF

    # Add include to printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    if [ -f "$pcfg" ]; then
        if ! grep -q "btt_eddy" "$pcfg"; then
            echo "" >> "$pcfg"
            echo "# --- BTT Eddy Probe ---" >> "$pcfg"
            echo "[include btt_eddy/*.cfg]" >> "$pcfg"
        fi
    fi
    
    draw_success "BTT Eddy config created!"
    echo "  Location: $eddy_dir/eddy.cfg"
    echo "  [i] Adjust pin, offsets, and mesh size for your setup!"
    echo "  [i] Requires BTT Eddy sensor firmware!"
    read -p "  Press Enter..."
}

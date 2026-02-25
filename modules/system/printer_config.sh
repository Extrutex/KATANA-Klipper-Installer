#!/bin/bash
# ==============================================================================
# KATANA PRINTER CONFIG WIZARD
# ==============================================================================

function run_printer_config_wizard() {
    while true; do
        draw_header "PRINTER CONFIG WIZARD"
        
        echo "  [1] Create Basic printer.cfg"
        echo "  [2] Create Ender-3 Template"
        echo "  [3] Create Voron Template"
        echo "  [4] Create Custom Template"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> " ch
        
        case $ch in
            1) create_basic_printer_cfg ;;
            2) create_ender3_printer_cfg ;;
            3) create_voron_printer_cfg ;;
            4) create_custom_printer_cfg ;;
            b|B) return ;;
        esac
    done
}

function create_basic_printer_cfg() {
    draw_header "BASIC PRINTER CONFIG"
    
    local printer_name=""
    local serial_port=""
    local baudrate="250000"
    
    echo "  Enter printer name (e.g. my-printer): "
    read -r -p "  >> " printer_name
    
    echo "  Serial port (e.g. /dev/ttyUSB0): "
    read -r -p "  >> " serial_port
    
    echo "  Baud rate [250000]: "
    read -r -p "  >> " baudrate
    [ -z "$baudrate" ] && baudrate="250000"
    
    local config_dir="$HOME/printer_data/config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/printer.cfg" <<EOF
# ============================================================
# KATANAOS Generated printer.cfg
# Printer: $printer_name
# Generated: $(date)
# ============================================================

[mcu $printer_name]
serial: $serial_port
baud: $baudrate

[printer]
 kinematics: cartesian
 max_velocity: 300
 max_accel: 3000
 max_z_velocity: 5
 max_z_accel: 100

[stepper_x]
 pin: $printer_name:PA1
 step_pin: $printer_name:PA2
 dir_pin: $printer_name:PA3
 enable_pin: !$printer_name:PA4
 microsteps: 16
 rotation_distance: 40
 endstop_pin: ^$printer_name:PA5

[stepper_y]
 pin: $printer_name:PB0
 step_pin: $printer_name:PB1
 dir_pin: $printer_name:PB2
 enable_pin: !$printer_name:PB3
 microsteps: 16
 rotation_distance: 40
 endstop_pin: ^$printer_name:PB4

[stepper_z]
 pin: $printer_name:PB5
 step_pin: $printer_name:PB6
 dir_pin: $printer_name:PB7
 enable_pin: !$printer_name:PB8
 microsteps: 16
 rotation_distance: 8
 endstop_pin: ^$printer_name:PB9

[extruder]
 pin: $printer_name:PC0
 step_pin: $printer_name:PC1
 dir_pin: $printer_name:PC2
 enable_pin: !$printer_name:PC3
 microsteps: 16
 rotation_distance: 33.5
 nozzle_diameter: 0.400
 filament_diameter: 1.750

[heater_bed]
 heater_pin: $printer_name:PC4
 sensor_type: EPCOS100K
 sensor_pin: $printer_name:PC5

[fan]
 pin: $printer_name:PC6

[probe]
 pin: ^$printer_name:PC7

[bed_screws]
screw1: 100:100
screw2: 190:100
screw3: 190:190
screw4: 100:190
EOF
    
    log_success "Created $config_dir/printer.cfg"
    read -r -p "  Press Enter..."
}

function create_ender3_printer_cfg() {
    draw_header "ENDER-3 PRINTER CONFIG"
    
    local config_dir="$HOME/printer_data/config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/printer.cfg" <<'EOF'
# ============================================================
# KATANAOS Generated - Ender-3 Template
# ============================================================

[mcu serLCD]
serial: /dev/ttyUSB0

[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 5000
max_z_velocity: 15
max_z_accel: 100

[stepper_x]
step_pin: serLCD:PB13
dir_pin: serLCD:PB12
enable_pin: !serLCD:PB11
microsteps: 16
rotation_distance: 40
endstop_pin: ^serLCD:PB2

[stepper_y]
step_pin: serLCD:PB10
dir_pin: serLCD:PB1
enable_pin: !serLCD:PB0
microsteps: 16
rotation_distance: 40
endstop_pin: ^serLCD:PB3

[stepper_z]
step_pin: serLCD:PB14
dir_pin: serLCD:PB13
enable_pin: !serLCD:PB12
microsteps: 16
rotation_distance: 8
endstop_pin: ^serLCD:PB1

[extruder]
step_pin: serLCD:PB0
dir_pin: !serLCD:PA4
enable_pin: !serLCD:PA3
microsteps: 16
rotation_distance: 33.5
nozzle_diameter: 0.400
filament_diameter: 1.750
heater_pin: serLCD:PA6
sensor_type: ATC Semitec 104GT-2
sensor_pin: serLCD:PA5

[heater_bed]
heater_pin: serLCD:PA7
sensor_type: EPCOS100K
sensor_pin: serLCD:PA0

[fan]
pin: serLCD:PA1

[probe]
pin: ^serLCD:PA2

[bed_screws]
screw1: 110:107
screw2: 197:110
screw3: 195:195
screw4: 108:195

[bltouch]
sensor_pin: ^serLCD:PA2
control_pin: serLCD:PA3
stow_on_touch: True
probe_with_touch_mode: False
pin_up_reports_not_triggered: True

[safe_z_home]
home_xy_position: 117.5:117.5
z_hop: 10

[print_start]
gcode:
    M117 Print Start
    G28

[print_end]
gcode:
    M104 S0
    M140 S0
    G28 X Y
    M117 Print Complete
EOF
    
    draw_success "Created Ender-3 config at $config_dir/printer.cfg"
    read -r -p "  Press Enter..."
}

function create_voron_printer_cfg() {
    draw_header "VORON PRINTER CONFIG"
    
    local config_dir="$HOME/printer_data/config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/printer.cfg" <<'EOF'
# ============================================================
# KATANAOS Generated - Voron 2.4 / Trident Template
# ============================================================

[mcu]
serial: /tmp/klipper.sock

[printer]
kinematics: corexy
max_velocity: 500
max_accel: 20000
max_z_velocity: 20
max_z_accel: 350

# --- X / Y STEPPERS (CoreXY) ---
[stepper_x]
step_pin: PB0
dir_pin: !PB1
enable_pin: !PC5
microsteps: 16
rotation_distance: 40

[stepper_y]
step_pin: PD11
dir_pin: !PD10
enable_pin: !PC6
microsteps: 16
rotation_distance: 40

# --- Z STEPPERS (4-Point) ---
[stepper_z]
step_pin: PC13
dir_pin: !PC14
enable_pin: !PC15
rotation_distance: 40

[stepper_z1]
step_pin: PA15
dir_pin: !PA14
enable_pin: !PA13
rotation_distance: 40

[stepper_z2]
step_pin: PA4
dir_pin: !PA3
enable_pin: !PA2
rotation_distance: 40

[stepper_z3]
step_pin: PB3
dir_pin: !PB4
enable_pin: !PB5
rotation_distance: 40

# --- EXTRUDER ---
[extruder]
step_pin: PB7
dir_pin: !PB6
enable_pin: !PB5
microsteps: 16
rotation_distance: 22.676
nozzle_diameter: 0.400
filament_diameter: 1.750

[heater_bed]
heater_pin: P2.4
sensor_type: MAX31865
sensor_pin: P0.23
spi_bus: spidev1.0

[fan]
pin: P2.3

# --- PROBE ---
[probe]
pin: P1.20

# --- CHAMBER FAN ---
[heater_fan chamber_fan]
pin: P1.22
max_power: 1.0
fan_speed: 0.5

# --- HOME POSITIONS ---
[safe_z_home]
home_xy_position: 175:175
z_hop: 20

[home_xy]
position_min: -5

# --- SCREWS ---
[bed_screws]
screw1: 154:154
screw2: 346:154
screw3: 346:346
screw4: 154:346

# --- MACROS ---
[gcode_macro PRINT_START]
gcode:
    M117 Starting Print...
    G28
    G32

[gcode_macro PRINT_END]
gcode:
    M104 S0
    M140 S0
    G28 X Y
    M117 Print Complete
EOF
    
    draw_success "Created Voron config at $config_dir/printer.cfg"
    read -r -p "  Press Enter..."
}

function create_custom_printer_cfg() {
    draw_header "CUSTOM PRINTER CONFIG"
    
    echo "  This will create a minimal printer.cfg template"
    echo "  You will need to fill in your specific pinout"
    echo ""
    read -r -p "  Press Enter to continue..."
    
    local config_dir="$HOME/printer_data/config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/printer.cfg" <<'EOF'
# ============================================================
# KATANAOS Generated - Custom Printer Template
# ============================================================
# IMPORTANT: Edit this file with your MCU pinout!
# ============================================================

[mcu]
serial: /dev/ttyUSB0

[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 3000
max_z_velocity: 5
max_z_accel: 100

# --- STEPPERS ---
# Replace pin numbers with your actual board pins

[stepper_x]
step_pin: 
dir_pin: 
enable_pin: 
microsteps: 16
rotation_distance: 40

[stepper_y]
step_pin: 
dir_pin: 
enable_pin: 
microsteps: 16
rotation_distance: 40

[stepper_z]
step_pin: 
dir_pin: 
enable_pin: 
microsteps: 16
rotation_distance: 8

[extruder]
step_pin: 
dir_pin: 
enable_pin: 
microsteps: 16
rotation_distance: 33.5
nozzle_diameter: 0.400
filament_diameter: 1.750

# --- HEATERS ---
[heater_bed]
heater_pin: 
sensor_type: EPCOS100K
sensor_pin: 

# --- FANS ---
[fan]
pin: 

# --- ENDSTOPS ---
# Uncomment for homing:
#[stepper_x]
#endstop_pin: ^

#[stepper_y]
#endstop_pin: ^

#[stepper_z]
#endstop_pin: ^
EOF
    
    draw_success "Created custom template at $config_dir/printer.cfg"
    echo "  Please edit the file and add your board-specific pins!"
    read -r -p "  Press Enter..."
}

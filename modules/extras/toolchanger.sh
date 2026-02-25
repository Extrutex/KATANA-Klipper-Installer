#!/bin/bash
# ==============================================================================
# KATANA MODULE: TOOLCHANGER
# Multi-Tool Support for Klipper
# ==============================================================================

function run_toolchanger_menu() {
    while true; do
        draw_header "KATANA TOOLCHANGER"
        
        local tc_status="NOT CONFIGURED"
        if [ -d "$HOME/printer_data/config/macros/toolchanger" ]; then
            tc_status="${C_GREEN}CONFIGURED${NC}"
        fi
        
        echo ""
        echo "  Status: [$tc_status]"
        echo ""
        echo "  --- Setup ---"
        echo "  ${C_NEON}[1]${NC}  Quick Setup (Dual/Quad/Hex)"
        echo "  ${C_NEON}[2]${NC}  Custom Multi-Tool"
        echo "  ${C_NEON}[3]${NC}  Tool Calibration"
        echo ""
        echo "  --- Remove ---"
        echo "  ${C_RED}[4]${NC}  Remove Toolchanger Config"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " cmd
        
        case $cmd in
            1) quick_toolchanger_setup ;;
            2) custom_toolchanger ;;
            3) tool_calibration ;;
            4) remove_toolchanger ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function quick_toolchanger_setup() {
    draw_header "QUICK TOOLCHANGER SETUP"
    echo ""
    echo "  Select number of tools:"
    echo "  [2] Dual Extruder"
    echo "  [4] Quad Extruder"
    echo "  [6] Six Tool"
    echo "  [B] Back"
    echo ""
    read -r -p "  >> SELECT: " selection
    
    local num_tools=2
    case $selection in
        2) num_tools=2 ;;
        4) num_tools=4 ;;
        6) num_tools=6 ;;
        [bB]) return ;;
        *) log_error "Invalid selection."; return ;;
    esac
    
    log_info "Setting up $num_tools tools..."
    
    local macro_dir="$HOME/printer_data/config/macros/toolchanger"
    mkdir -p "$macro_dir"
    
    # Generate toolchange macros
    for ((i=0; i<num_tools; i++)); do
        cat > "$macro_dir/t${i}.cfg" << EOF
[gcode_macro T${i}]
description: Select tool ${i}
gcode:
    T${i}
    SET_GCODE_VARIABLE MACRO=ACTIVE_TOOL VARIABLE=tool VALUE=${i}
    { action_respond_info("Tool changed to T${i}") }
EOF
    done
    
    # Create active tool tracker
    cat > "$macro_dir/toolchanger_base.cfg" << EOF
[gcode_macro ACTIVE_TOOL]
description: Track active tool
variable_tool: 0
gcode:
    { action_respond_info("Active tool: T" ~ printer["gcode_macro ACTIVE_TOOL"].tool) }
EOF
    
    # Add include to printer.cfg
    local cfg_file="$HOME/printer_data/config/printer.cfg"
    if [ -f "$cfg_file" ]; then
        if ! grep -q "macros/toolchanger" "$cfg_file" 2>/dev/null; then
            cp "$cfg_file" "$cfg_file.bak.toolchanger"
            echo "" >> "$cfg_file"
            echo "# --- KATANA TOOLCHANGER ---" >> "$cfg_file"
            echo "[include macros/toolchanger/*.cfg]" >> "$cfg_file"
            log_info "Added include to printer.cfg"
        fi
    fi
    
    log_success "$num_tools tools configured!"
    echo "  Macros: $macro_dir"
    echo "  Use T0, T1, T2... to switch tools"
    read -r -p "  Press Enter..."
}

function custom_toolchanger() {
    draw_header "CUSTOM TOOLCHANGER"
    echo ""
    echo "  How many tools? (2-16)"
    read -r -p "  >> " num_tools
    
    if ! [[ "$num_tools" =~ ^[0-9]+$ ]] || [ "$num_tools" -lt 2 ] || [ "$num_tools" -gt 16 ]; then
        log_error "Invalid number (2-16)"
        return
    fi
    
    local macro_dir="$HOME/printer_data/config/macros/toolchanger"
    mkdir -p "$macro_dir"
    
    for ((i=0; i<num_tools; i++)); do
        cat > "$macro_dir/t${i}.cfg" << EOF
[gcode_macro T${i}]
description: Select tool ${i}
gcode:
    # Custom toolchange logic for T${i}
    T${i}
    # Add your parking/positioning here
EOF
    done
    
    log_success "$num_tools tools configured!"
    echo "  Edit the macros in: $macro_dir"
    read -r -p "  Press Enter..."
}

function tool_calibration() {
    draw_header "TOOL CALIBRATION"
    echo ""
    echo "  [1] Calibrate Z-Offset per Tool"
    echo "  [2] Calibrate Extrusion Ratio"
    echo "  [B] Back"
    echo ""
    read -r -p "  >> SELECT: " selection
    
    local macro_dir="$HOME/printer_data/config/macros/toolchanger"
    mkdir -p "$macro_dir"
    
    case $selection in
        1)
            cat > "$macro_dir/calibrate_z_offset.cfg" << 'EOF'
[gcode_macro CALIBRATE_Z_TOOL]
description: Calibrate Z offset for active tool
gcode:
    {% set tool = printer["gcode_macro ACTIVE_TOOL"].tool %}
    { action_respond_info("Calibrating Z for Tool T" ~ tool) }
    G28 Z
    PROBE_CALIBRATE
EOF
            log_success "Z-Offset calibration macro created"
            ;;
        2)
            log_info "Use Klipper's built-in extrusion calibration."
            echo "  1. Mark filament at 120mm"
            echo "  2. Extrude 100mm: G1 E100 F50"
            echo "  3. Measure remaining, adjust rotation_distance"
            ;;
        [bB]) return ;;
    esac
    
    read -r -p "  Press Enter..."
}

function remove_toolchanger() {
    draw_header "REMOVE TOOLCHANGER"
    
    local macro_dir="$HOME/printer_data/config/macros/toolchanger"
    
    if [ ! -d "$macro_dir" ]; then
        log_warn "No toolchanger config found."
        read -r -p "  Press Enter..."
        return
    fi
    
    echo "  Files to remove:"
    ls "$macro_dir/" 2>/dev/null
    echo ""
    read -r -p "  Remove all toolchanger configs? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY] ]]; then return; fi
    
    log_info "Removing toolchanger macros..."
    rm -rf "$macro_dir"
    
    # Clean printer.cfg
    local cfg_file="$HOME/printer_data/config/printer.cfg"
    if [ -f "$cfg_file" ] && grep -q "toolchanger" "$cfg_file"; then
        local tmpfile
        tmpfile=$(mktemp)
        grep -v "macros/toolchanger" "$cfg_file" | grep -v "# --- KATANA TOOLCHANGER ---" > "$tmpfile"
        mv "$tmpfile" "$cfg_file"
        log_success "printer.cfg cleaned."
    fi
    
    log_success "Toolchanger removed!"
    read -r -p "  Press Enter..."
}

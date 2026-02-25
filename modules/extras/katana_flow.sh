#!/bin/bash
# ==============================================================================
# KATANA MODULE: KATANA-FLOW
# Print Lifecycle Macro System
# 4 macros: FLOW_START → FLOW_PARK → FLOW_PURGE → FLOW_END
# ==============================================================================

FLOW_FILES="flow_start.cfg flow_park.cfg flow_purge.cfg flow_end.cfg"

function install_katana_flow() {
    while true; do
        draw_header "KATANA-FLOW (Print Lifecycle)"
        
        local flow_status="NOT INSTALLED"
        if [ -d "$HOME/printer_data/config/katana_flow" ]; then
            flow_status="${C_GREEN}INSTALLED${NC}"
        fi
        
        echo ""
        echo "  Status: [$flow_status]"
        echo ""
        echo "  ${C_NEON}[1]${NC}  Install KATANA-FLOW"
        echo "  ${C_RED}[2]${NC}  Remove KATANA-FLOW"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> COMMAND: " ch
        
        case $ch in
            1) do_install_flow ;;
            2) do_remove_flow ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function do_install_flow() {
    draw_header "INSTALL KATANA-FLOW"
    echo ""
    echo "  KATANA-FLOW is a complete print lifecycle system:"
    echo ""
    echo "    FLOW_START  — Home, Heat, Park, Purge (replaces START_PRINT)"
    echo "    FLOW_PARK   — Position near first object"
    echo "    FLOW_PURGE  — X-Blade cross purge pattern"
    echo "    FLOW_END    — Retract, Present, Cooldown (replaces END_PRINT)"
    echo ""
    read -r -p "  Install? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local flow_dir="$cfg_dir/katana_flow"
    local pcfg="$cfg_dir/printer.cfg"
    local src_dir="$CONFIGS_DIR/katana_flow"
    
    if [ ! -d "$cfg_dir" ]; then
        log_error "Config directory not found at $cfg_dir"
        read -r -p "  Press Enter..."
        return
    fi
    
    mkdir -p "$flow_dir"
    
    log_info "Deploying KATANA-FLOW macros..."
    local failed=0
    for f in $FLOW_FILES; do
        if [ -f "$src_dir/$f" ]; then
            cp "$src_dir/$f" "$flow_dir/$f"
        else
            log_error "Missing: $src_dir/$f"
            failed=1
        fi
    done
    
    if [ "$failed" -eq 1 ]; then
        log_error "Some files missing. Check your KATANA installation."
        read -r -p "  Press Enter..."
        return
    fi
    
    if [ -f "$pcfg" ]; then
        if grep -q "katana_flow" "$pcfg"; then
            log_warn "KATANA-FLOW already included in printer.cfg"
        else
            cp "$pcfg" "$pcfg.bak.katanaflow"
            echo "" >> "$pcfg"
            echo "# --- KATANA-FLOW ---" >> "$pcfg"
            echo "[include katana_flow/*.cfg]" >> "$pcfg"
            log_info "Added include to printer.cfg (backup: printer.cfg.bak.katanaflow)"
        fi
    fi
    
    log_success "KATANA-FLOW installed!"
    echo ""
    echo "  Slicer Start G-Code:  FLOW_START BED=60 NOZZLE=210"
    echo "  Slicer End G-Code:    FLOW_END"
    echo ""
    read -r -p "  Press Enter..."
}

function do_remove_flow() {
    draw_header "REMOVE KATANA-FLOW"
    echo ""
    read -r -p "  Remove KATANA-FLOW completely? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local flow_dir="$cfg_dir/katana_flow"
    local pcfg="$cfg_dir/printer.cfg"
    
    log_info "Removing config files..."
    rm -rf "$flow_dir"
    
    if [ -f "$pcfg" ]; then
        log_info "Cleaning printer.cfg..."
        local tmpfile
        tmpfile=$(mktemp)
        grep -v "katana_flow" "$pcfg" | grep -v "# --- KATANA-FLOW ---" > "$tmpfile"
        mv "$tmpfile" "$pcfg"
        log_success "printer.cfg cleaned."
    fi
    
    log_success "KATANA-FLOW removed!"
    read -r -p "  Press Enter..."
}

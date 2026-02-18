#!/bin/bash
# modules/extras/katana_flow.sh
# KATANA-FLOW: Print Lifecycle Macro System
# 4 macros: FLOW_START → FLOW_PARK → FLOW_PURGE → FLOW_END

source "$MODULES_DIR/extras/install_shaketune.sh"
source "$MODULES_DIR/system/moonraker_update_manager.sh"

FLOW_FILES="flow_start.cfg flow_park.cfg flow_purge.cfg flow_end.cfg"

function install_katana_flow() {
    while true; do
        draw_header "🧩 EXTRAS & TUNING"
        echo ""
        echo "  --- KATANA-FLOW (Print Lifecycle) ---"
        echo "  [1] Install KATANA-FLOW"
        echo "  [2] Remove KATANA-FLOW"
        echo ""
        echo "  --- ShakeTune (Input Shaper Tuning) ---"
        echo "  [3] Install ShakeTune"
        echo "  [4] Remove ShakeTune"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) do_install_flow ;;
            2) do_remove_flow ;;
            3) install_shaketune ;;
            4) remove_shaketune ;;
            [bB]) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function remove_shaketune() {
    draw_header "REMOVE SHAKETUNE"
    echo ""
    read -p "  Remove ShakeTune completely? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local repo_dir="$HOME/klippain_shaketune"
    local venv_dir="$HOME/klippain_shaketune-env"
    
    log_info "Removing ShakeTune..."
    rm -rf "$repo_dir" "$venv_dir"
    rm -f "$HOME/klipper/klippy/extras/shaketune.py"
    
    draw_success "ShakeTune removed!"
    read -p "  Press Enter..."
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
    read -p "  Install? [y/N]: " yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    local cfg_dir="$HOME/printer_data/config"
    local flow_dir="$cfg_dir/katana_flow"
    local pcfg="$cfg_dir/printer.cfg"
    local src_dir="$CONFIGS_DIR/katana_flow"
    
    if [ ! -d "$cfg_dir" ]; then
        draw_error "Config directory not found at $cfg_dir"
        read -p "  Press Enter..."
        return
    fi
    
    mkdir -p "$flow_dir"
    
    # Deploy macro files
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
        draw_error "Some files missing. Check your KATANA installation."
        read -p "  Press Enter..."
        return
    fi
    
    # Backup + add include
    if [ -f "$pcfg" ]; then
        if grep -q "katana_flow" "$pcfg"; then
            draw_warn "KATANA-FLOW already included in printer.cfg"
        else
            cp "$pcfg" "$pcfg.bak.katanaflow"
            echo "" >> "$pcfg"
            echo "# --- KATANA-FLOW ---" >> "$pcfg"
            echo "[include katana_flow/*.cfg]" >> "$pcfg"
            log_info "Added include to printer.cfg (backup: printer.cfg.bak.katanaflow)"
        fi
    fi
    
    draw_success "KATANA-FLOW installed!"
    echo ""
    echo "  Slicer Start G-Code:  FLOW_START BED=60 NOZZLE=210"
    echo "  Slicer End G-Code:    FLOW_END"
    echo ""
    read -p "  Press Enter..."
}

function do_remove_flow() {
    draw_header "REMOVE KATANA-FLOW"
    echo ""
    read -p "  Remove KATANA-FLOW completely? [y/N]: " yn
    
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
        draw_success "printer.cfg cleaned."
    fi
    
    draw_success "KATANA-FLOW removed!"
    read -p "  Press Enter..."
}

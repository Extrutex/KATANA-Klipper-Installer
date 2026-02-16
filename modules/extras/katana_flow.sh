#!/bin/bash
# modules/extras/katana_flow.sh

source "$MODULES_DIR/extras/install_shaketune.sh"

function install_katana_flow() {
    while true; do
        draw_header "🧩 EXTRAS & TUNING"
        echo ""
        echo "  --- KATANA-FLOW (Smart Purge & Park) ---"
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
    echo "  Select Include Method:"
    echo "  [1] Variant A: Simple Include ([include katana_flow/*.cfg])"
    echo "  [2] Variant B: With Section Header ([KatanaFlow])"
    echo ""
    read -p "  >> SELECT: " variant_ch
    
    local variant="A"
    case $variant_ch in
        1) variant="A" ;;
        2) variant="B" ;;
        *) log_error "Invalid selection."; return ;;
    esac
    
    local cfg_dir="$HOME/printer_data/config"
    local flow_dir="$cfg_dir/katana_flow"
    local pcfg="$cfg_dir/printer.cfg"
    
    # 1. Check Config Directory
    if [ ! -d "$cfg_dir" ]; then
        draw_error "Config directory not found at $cfg_dir"
        read -p "  Press Enter..."
        return
    fi
    
    # 2. Create Flow Directory
    mkdir -p "$flow_dir"
    
    # 3. Copy Config Files
    log_info "Deploying Macro files..."
    cp "$CONFIGS_DIR/katana_flow/smart_purge.cfg" "$flow_dir/smart_purge.cfg"
    cp "$CONFIGS_DIR/katana_flow/smart_park.cfg" "$flow_dir/smart_park.cfg"
    
    # 4. Backup printer.cfg
    if [ -f "$pcfg" ]; then
        cp "$pcfg" "$pcfg.bak.katanaflow"
        log_info "Backup created: printer.cfg.bak.katanaflow"
    fi
    
    # 5. Add Include based on variant
    if [ -f "$pcfg" ]; then
        # Check if already installed
        if grep -q "katana_flow" "$pcfg"; then
            draw_warn "KATANA-FLOW already seems to be included!"
            read -p "  Re-install anyway? [y/N]: " yn
            if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
        fi
        
        if [ "$variant" = "A" ]; then
            # Variant A: Simple Include
            echo "" >> "$pcfg"
            echo "# --- KATANA-FLOW ---" >> "$pcfg"
            echo "[include katana_flow/*.cfg]" >> "$pcfg"
            draw_success "Installed with Variant A (Simple Include)"
        else
            # Variant B: With Section Header
            echo "" >> "$pcfg"
            echo "# --- KATANA-FLOW ---" >> "$pcfg"
            echo "[KatanaFlow]" >> "$pcfg"
            echo "" >> "$pcfg"
            echo "[include katana_flow/smart_purge.cfg]" >> "$pcfg"
            echo "[include katana_flow/smart_park.cfg]" >> "$pcfg"
            draw_success "Installed with Variant B (Section Header)"
        fi
    else
        draw_error "printer.cfg not found!"
        echo "  Please manually add the include to your printer.cfg:"
        if [ "$variant" = "A" ]; then
            echo "  [include katana_flow/*.cfg]"
        else
            echo "  [KatanaFlow]"
            echo "  [include katana_flow/smart_purge.cfg]"
            echo "  [include katana_flow/smart_park.cfg]"
        fi
    fi
    
    echo ""
    echo "  [i] IMPORTANT: Add to your START_PRINT macro:"
    echo "      FLOW_PARK    # Park near object"
    echo "      FLOW_PURGE  # Blade-style purge"
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
    
    # 1. Remove config files
    log_info "Removing config files..."
    rm -rf "$flow_dir"
    
    # 2. Remove include lines from printer.cfg
    if [ -f "$pcfg" ]; then
        log_info "Cleaning printer.cfg..."
        
        # Create temp file and filter out KatanaFlow lines
        local tmpfile=$(mktemp)
        
        # Remove: # --- KATANA-FLOW ---
        # Remove: [include katana_flow/*.cfg]
        # Remove: [include katana_flow/smart_purge.cfg]
        # Remove: [include katana_flow/smart_park.cfg]
        # Remove: [KatanaFlow]
        
        grep -v "katana_flow" "$pcfg" | grep -v "# --- KATANA-FLOW ---" | grep -v "^\[KatanaFlow\]" > "$tmpfile"
        
        mv "$tmpfile" "$pcfg"
        draw_success "printer.cfg cleaned."
    fi
    
    draw_success "KATANA-FLOW removed completely!"
    read -p "  Press Enter..."
}

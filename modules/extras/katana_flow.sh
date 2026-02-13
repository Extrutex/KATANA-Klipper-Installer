#!/bin/bash
# modules/extras/katana_flow.sh

function install_katana_flow() {
    draw_header "KATANA-FLOW: SMART PURGE & MESH"
    echo "  This module installs the 'Smart Purge' and 'Adaptive Mesh'"
    echo "  macros (KAMP-compatible) into your configuration."
    echo ""
    echo "  1) Install KATANA-FLOW"
    echo "  2) Remove KATANA-FLOW"
    echo "  B) Back"
    read -p "  >> " ch
    
    case $ch in
        1) do_install_flow ;;
        2) do_remove_flow ;;
        [bB]) return ;;
    esac
}

function do_install_flow() {
    log_info "Installing KATANA-FLOW..."
    
    local cfg_dir="$HOME/printer_data/config"
    local flow_dir="$cfg_dir/katana_flow"
    
    # 1. Ensure Config Directory
    if [ ! -d "$cfg_dir" ]; then
        log_error "Config directory not found at $cfg_dir"
        return
    fi
    
    mkdir -p "$flow_dir"
    
    # 2. Copy Config Files
    log_info "Deploying Macro files..."
    cp "$CONFIGS_DIR/katana_flow/smart_purge.cfg" "$flow_dir/smart_purge.cfg"
    cp "$CONFIGS_DIR/katana_flow/adaptive_mesh.cfg" "$flow_dir/adaptive_mesh.cfg"
    
    # 3. Inject Include into printer.cfg
    local pcfg="$cfg_dir/printer.cfg"
    local inc_line="[include katana_flow/*.cfg]"
    
    if [ -f "$pcfg" ]; then
        if grep -Fq "$inc_line" "$pcfg"; then
            log_info "Include line already exists in printer.cfg."
        else
            log_info "Injecting include line into printer.cfg..."
            # Backup first
            cp "$pcfg" "$pcfg.bak.flow"
            
            # Prepend or Append? Append is safer for overrides, Prepend safer for distinct macros.
            # We append to ensures macros are available.
            echo "" >> "$pcfg"
            echo "# --- KATANA-FLOW ---" >> "$pcfg"
            echo "$inc_line" >> "$pcfg"
            log_success "Injection successful."
        fi
    else
        log_warn "printer.cfg not found. You must manually add '$inc_line'."
    fi
    
    log_success "KATANA-FLOW Installed."
    echo "  [i] IMPORTANT: Update your START_PRINT macro to use:"
    echo "      FLOW_MESH"
    echo "      FLOW_PURGE"
    read -p "  Press Enter..."
}

function do_remove_flow() {
    log_info "Removing KATANA-FLOW..."
    # Warning: We don't remove the include line automatically to avoid sed accidents
    # We just allow the user to delete the folder
    
    rm -rf "$HOME/printer_data/config/katana_flow"
    log_success "Files removed. Please manually remove '[include katana_flow/*.cfg]' from printer.cfg"
    read -p "  Press Enter..."
}

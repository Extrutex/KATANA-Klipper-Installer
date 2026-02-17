#!/bin/bash
# ==============================================================================
# KATANA MODULE: MOONRAKER REPAIR
# Fixes corrupted configuration files to restore connectivity.
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    # Auto-detect root if script is run directly
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Start at modules/system, go up 2 levels
    KATANA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
    
    if [ -f "$KATANA_ROOT/core/logger.sh" ]; then
        source "$KATANA_ROOT/core/logger.sh"
    else
        echo "Logger not found at $KATANA_ROOT/core/logger.sh"
        # Fallback to simple echo functions if logger is missing
        function log_info() { echo "[INFO] $1"; }
        function log_error() { echo "[ERROR] $1"; }
        function log_success() { echo "[OK] $1"; }
        function log_warn() { echo "[WARN] $1"; }
    fi
fi

function repair_moonraker_config() {
    log_info "Diagnosing Moonraker Configuration..."
    
    local config_file="$HOME/printer_data/config/moonraker.conf"
    local template_file="$KATANA_ROOT/configs/templates/moonraker.conf"
    
    # Check if config exists and has valid content
    if [ -f "$config_file" ] && grep -q "\[server\]" "$config_file"; then
        log_success "moonraker.conf seems valid (contains [server] section)."
    else
        log_error "moonraker.conf is missing or corrupt!"
        log_info "Restoring from template..."
        
        # Ensure template exists
        if [ ! -f "$template_file" ]; then
            log_error "Template not found at $template_file"
            return 1
        fi
        
        # Backup old config if it exists
        if [ -f "$config_file" ]; then
            cp "$config_file" "${config_file}.broken.$(date +%s)"
            log_warn "Backed up broken config."
        fi
        
        # copy template
        cp "$template_file" "$config_file"
        
        # Fix permissions
        chown $USER:$USER "$config_file"
        
        log_success "Restored moonraker.conf from template."
        
        # Restart service
        log_info "Restarting Moonraker..."
        sudo systemctl restart moonraker
        
        sleep 2
        if systemctl is-active --quiet moonraker; then
            log_success "Moonraker is running!"
        else
            log_error "Moonraker failed to start even after repair."
            systemctl status moonraker --no-pager
        fi
    fi
}

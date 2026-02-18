#!/bin/bash
# ==============================================================================
# KATANA MODULE: BACKUP MANAGER
# Automated backup & restore for Klipper configs & databases.
# ==============================================================================

if [ -z "$KATANA_ROOT" ]; then
    KATANA_ROOT="$HOME/KATANA_INSTALLER"
    source "$KATANA_ROOT/core/logger.sh"
    source "$KATANA_ROOT/core/env_check.sh"
fi

BACKUP_DIR="$HOME/katana_backups"

function run_backup_menu() {
    mkdir -p "$BACKUP_DIR"
    
    while true; do
        draw_header "BACKUP & RESTORE"
        echo "  Location: $BACKUP_DIR"
        echo ""
        echo "  [1] Create Full Backup (Config + DB)"
        echo "  [2] List Backups"
        echo "  [3] Restore Backup from Archive"
        echo "  [4] GitHub Push (Config only)"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) create_backup ;;
            2) list_backups ;;
            3) restore_backup ;;
            4) push_config_to_git ;;
            b|B) return ;;
            *) log_error "Invalid Selection" ;;
        esac
    done
}

function create_backup() {
    log_info "Starting Backup Process..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="katana_backup_$timestamp.zip"
    local target="$BACKUP_DIR/$filename"
    
    # Check source dirs
    local config_dir="$HOME/printer_data/config"
    local db_dir="$HOME/printer_data/database"
    
    if [ ! -d "$config_dir" ]; then
        log_error "Config directory not found: $config_dir"
        return 1
    fi
    
    # Archive config + database
    
    log_info "Archiving System..."
    
    # Check if zip is installed
    if ! command -v zip &> /dev/null; then
        sudo apt-get install -y zip
    fi
    
    zip -r "$target" "$config_dir" "$db_dir" -x "*.gcode" "*.log" > /dev/null
    
    if [ -f "$target" ]; then
        log_success "Backup created: $filename"
        
        # Rotation: Keep only last 5
        log_info "Rotating old backups..."
        ls -t "$BACKUP_DIR"/katana_backup_*.zip | tail -n +6 | xargs -I {} rm -- {} 2>/dev/null
    else
        log_error "Backup failed!"
    fi
    
    read -p "  Press Enter..."
}

function list_backups() {
    draw_header "AVAILABLE BACKUPS"
    ls -lh "$BACKUP_DIR"
    echo ""
    read -p "  Press Enter..."
}

function push_config_to_git() {
    draw_header "GIT BACKUP"
    local config_dir="$HOME/printer_data/config"
    
    if [ ! -d "$config_dir/.git" ]; then
        log_warn "No Git repository found in $config_dir"
        echo "  Would you like to initialize one?"
        read -p "  [y/N]: " yn
        if [[ "$yn" =~ ^[yY] ]]; then
            cd "$config_dir"
            git init
            git add .
            git commit -m "Initial Check-In via KATANA"
            log_success "Repo initialized."
        else
            return
        fi
    fi
    
    log_info "Pushing to Git..."
    cd "$config_dir"
    git add .
    git commit -m "Auto-Backup: $(date)" || echo "Nothing to commit"
    
    # Push if remote exists
    if git remote -v | grep -q "origin"; then
        git push || log_error "Push failed. Check SSH keys/Auth."
    else
        log_warn "No remote 'origin' configured. Committed locally only."
    fi
    

    read -p "  Press Enter..."
}

function restore_backup() {
    draw_header "RESTORE BACKUP"
    
    # 1. List available backups
    local backups=($(ls "$BACKUP_DIR"/*.zip 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        log_warn "No backups found in $BACKUP_DIR."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Available Backups:"
    local i=1
    for backup in "${backups[@]}"; do
        echo "  [$i] $(basename "$backup")"
        ((i++))
    done
    echo ""
    echo "  [B] Back"
    echo ""
    
    read -p "  >> SELECT BACKUP TO RESTORE: " choice
    
    if [[ "$choice" =~ ^[bB]$ ]]; then return; fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#backups[@]}" ]; then
        log_error "Invalid selection."
        return
    fi
    
    local target_backup="${backups[$((choice-1))]}"
    local backup_name=$(basename "$target_backup")
    
    echo ""
    log_warn "WARNING: This will OVERWRITE your current configuration!"
    echo "  Restoring: $backup_name"
    read -p "  Type 'RESTORE' to confirm: " confirm
    
    if [ "$confirm" != "RESTORE" ]; then
        log_info "Restore cancelled."
        return
    fi
    
    log_info "Stopping services..."
    sudo systemctl stop klipper moonraker 2>/dev/null
    
    log_info "Extracting backup..."
    # Unzip to temp location first for safety
    local temp_restore="/tmp/katana_restore_$(date +%s)"
    mkdir -p "$temp_restore"
    
    if unzip -q "$target_backup" -d "$temp_restore"; then
        # Check structure (we expect printer_data/config and maybe printer_data/database inside or just config)
        # Our create_backup zips "$config_dir" and "$db_dir" directly.
        # So inside zip we likely have full structure or flat files depending on zip command relative paths.
        

        
        
        # Restore Config
        if [ -d "$temp_restore/home/$USER/printer_data/config" ]; then
             log_info "Restoring Config (Structure A)..."
             cp -r "$temp_restore/home/$USER/printer_data/config/"* "$HOME/printer_data/config/"
        elif [ -d "$temp_restore/config" ]; then
             log_info "Restoring Config (Structure B)..."
             cp -r "$temp_restore/config/"* "$HOME/printer_data/config/"
        else
             log_warn "Could not automatically detect config structure in zip. Attempting heuristic copy..."
             # Try to find printer.cfg
             local pcfg=$(find "$temp_restore" -name "printer.cfg")
             if [ -n "$pcfg" ]; then
                 local pcfg_dir=$(dirname "$pcfg")
                 cp -r "$pcfg_dir/"* "$HOME/printer_data/config/"
                 log_success "Config restored from $pcfg_dir"
             else
                 log_error "printer.cfg not found in backup!"
             fi
        fi
        
        # Restore Database (Moonraker)
        if [ -d "$temp_restore/home/$USER/printer_data/database" ]; then
             log_info "Restoring Database..."
             cp -r "$temp_restore/home/$USER/printer_data/database/"* "$HOME/printer_data/database/"
        fi
        
        # Cleanup
        rm -rf "$temp_restore"
        
        # Fix Permissions
        sudo chown -R $USER:$USER "$HOME/printer_data"
        
        log_success "Restore complete!"
        log_info "Restarting services..."
        sudo systemctl start klipper moonraker
    else
        log_error "Unzip failed."
    fi
    
    read -p "  Press Enter..."
}

#!/bin/bash
# ==============================================================================
# KATANA MODULE: THE VAULT
# Secure Backup & Restore System
# ==============================================================================

BACKUP_DIR="$HOME/katana_backups"
CONFIG_DIR="$HOME/printer_data/config"
DB_FILE="$HOME/printer_data/database/moonraker.db"

function vault_create() {
    draw_header "THE VAULT: CREATE BACKUP"
    
    # 1. Prepare
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y-%m-%d_%H-%M")
    local filename="backup_${timestamp}.zip"
    local filepath="$BACKUP_DIR/$filename"

    log_info "Snapshotting system..."
    
    if [ ! -d "$CONFIG_DIR" ]; then
        log_error "Config directory not found!"
        sleep 2; return
    fi

    # 2. Create Zip (relative paths from $HOME for safe restore)
    check_dependency "zip" "zip"

    log_info "Archiving to $filename..."
    local zip_args=("$CONFIG_DIR")
    if [ -f "$DB_FILE" ]; then
        zip_args+=("$DB_FILE")
    fi

    (cd "$HOME" && zip -r -q "$filepath" "${zip_args[@]#$HOME/}")

    if [ $? -eq 0 ]; then
        log_success "Backup verified: $filename"
    else
        log_error "Backup failed!"
        sleep 2; return
    fi

    # 3. Rotation (Keep last 5)
    log_info "Rotating old backups..."
    local old_backups=("$BACKUP_DIR"/backup_*.zip)
    if [ -e "${old_backups[0]}" ] && [ ${#old_backups[@]} -gt 5 ]; then
        # Sort by mtime, delete oldest
        local to_delete
        to_delete=$(printf '%s\n' "${old_backups[@]}" | xargs ls -1t | tail -n +6)
        if [ -n "$to_delete" ]; then
            echo "$to_delete" | xargs rm -f
            log_info "Purged old backups."
        fi
    fi

    echo ""
    echo "  [i] Backup stored in: ~/katana_backups"
    read -p "  Press [Enter] to continue..."
}

function vault_restore() {
    draw_header "THE VAULT: RESTORE SYSTEM"
    
    # Check for backups
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_error "No backups found in $BACKUP_DIR"
        sleep 2; return
    fi

    echo "  Available Backups:"
    echo ""
    
    # List backups sorted newest-first
    local backups=()
    while IFS= read -r -d '' f; do backups+=("$f"); done < <(find "$BACKUP_DIR" -maxdepth 1 -name 'backup_*.zip' -print0 | xargs -0 ls -1t 2>/dev/null | tr '\n' '\0')
    local i=1
    for bk in "${backups[@]}"; do
        echo "  [$i] $(basename "$bk")"
        ((i++))
    done
    echo ""
    echo "  [B] Back"
    echo ""
    
    read -p "  >> SELECT RESTORE POINT: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#backups[@]}" ]; then
        local target="${backups[$((choice-1))]}"
        log_warn "You are about to restore: $(basename "$target")"
        log_warn "Current config will be OVERWRITTEN."
        read -p "  Are you sure? (y/N): " confirm
        
        if [[ "$confirm" =~ ^[yY]$ ]]; then
            log_info "Restoring..."
            check_dependency "unzip" "unzip"
            
            # Restore to $HOME (backup uses relative paths from $HOME)
            unzip -o -q "$target" -d "$HOME"
            
            if [ $? -eq 0 ]; then
                log_success "System Restored."
                echo "  [!] A restart of Klipper is recommended."
            else
                log_error "Restore failed."
            fi
        fi
    fi
    read -p "  Press [Enter]..."
}

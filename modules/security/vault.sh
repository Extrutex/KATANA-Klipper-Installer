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

    # 2. Create Zip
    # Include config + moonraker db if present
    local file_list="$CONFIG_DIR"
    if [ -f "$DB_FILE" ]; then
        file_list="$file_list $DB_FILE"
    fi

    check_dependency "zip" "zip"

    log_info "Archiving to $filename..."
    zip -r -q "$filepath" $file_list

    if [ $? -eq 0 ]; then
        log_success "Backup verified: $filename"
    else
        log_error "Backup failed!"
        sleep 2; return
    fi

    # 3. Rotation (Keep last 5)
    log_info "Rotating old backups..."
    local count=$(ls -1 "$BACKUP_DIR"/backup_*.zip 2>/dev/null | wc -l)
    if [ "$count" -gt 5 ]; then
        # List oldest, delete
        ls -1t "$BACKUP_DIR"/backup_*.zip | tail -n +6 | xargs rm -f
        log_info "Purged $(($count - 5)) old backups."
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
    
    # List backups with numbers
    local backups=($(ls -1t "$BACKUP_DIR"/backup_*.zip))
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
            
            # Unzip to root ( since paths are absolute in zip? or relative? )
            # zip -r uses relative path if cd'd, or absolute if given absolute.
            # In vault_create we used absolute variables. zip usually strips leading slash.
            
            
            unzip -o -q "$target" -d / 
            
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

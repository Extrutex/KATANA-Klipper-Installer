#!/bin/bash
# ==============================================================================
# KATANA MODULE: BACKUP & RESTORE
# Complete backup and restore functionality
# ==============================================================================

function run_backup_restore() {
    while true; do
        draw_header "KATANA BACKUP & RESTORE"
        echo ""
        echo "  [1] CREATE BACKUP (printer_data)"
        echo "  [2] RESTORE FROM BACKUP"
        echo "  [3] LIST BACKUPS"
        echo "  [4] DELETE OLD BACKUPS"
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " cmd
        
        case $cmd in
            1) create_backup ;;
            2) restore_backup ;;
            3) list_backups ;;
            4) delete_old_backups ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function create_backup() {
    draw_header "CREATE BACKUP"
    
    local backup_dir="$HOME/katana_backups"
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +"%Y-%m-%d_%H-%M")
    local backup_name="katana_backup_${timestamp}"
    local backup_path="$backup_dir/${backup_name}.tar.gz"
    
    log_info "Creating backup: $backup_name"
    
    # Check if printer_data exists
    if [ ! -d "$HOME/printer_data" ]; then
        log_error "No printer_data directory found."
        read -p "  Press Enter..."
        return
    fi
    
    # Create backup
    cd "$HOME"
    tar -czf "$backup_path" \
        printer_data/config \
        printer_data/logs \
        printer_data/gcodes \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_path" | cut -f1)
        log_success "Backup created: $backup_path ($size)"
    else
        log_error "Backup failed!"
    fi
    
    read -p "  Press Enter..."
}

function restore_backup() {
    draw_header "RESTORE FROM BACKUP"
    
    local backup_dir="$HOME/katana_backups"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "No backups found."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  Available backups:"
    echo ""
    
    local backups=($(ls -1 "$backup_dir"/*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        log_error "No backups found."
        read -p "  Press Enter..."
        return
    fi
    
    local i=1
    for backup in "${backups[@]}"; do
        local size=$(du -h "$backup" | cut -f1)
        local name=$(basename "$backup")
        echo "  [$i] $name ($size)"
        ((i++))
    done
    
    echo ""
    echo "  [B] Back"
    echo ""
    read -p "  >> SELECT: " selection
    
    if [ "$selection" = "B" ] || [ "$selection" = "b" ]; then
        return
    fi
    
    local selected=$((selection - 1))
    if [ $selected -ge 0 ] && [ $selected -lt ${#backups[@]} ]; then
        local backup_file="${backups[$selected]}"
        
        log_warn "This will overwrite current printer_data!"
        echo "  Type 'YES' to confirm: "
        read -r confirm
        
        if [ "$confirm" = "YES" ]; then
            log_info "Restoring from backup..."
            
            # Stop services
            sudo systemctl stop klipper moonraker 2>/dev/null
            
            # Restore
            cd "$HOME"
            rm -rf printer_data/config printer_data/logs
            tar -xzf "$backup_file"
            
            # Fix permissions
            chown -R $USER:$USER printer_data
            
            # Start services
            sudo systemctl start klipper moonraker
            
            log_success "Restore complete!"
        else
            log_info "Cancelled."
        fi
    else
        log_error "Invalid selection."
    fi
    
    read -p "  Press Enter..."
}

function list_backups() {
    draw_header "AVAILABLE BACKUPS"
    
    local backup_dir="$HOME/katana_backups"
    
    if [ ! -d "$backup_dir" ]; then
        log_info "No backups directory found."
        read -p "  Press Enter..."
        return
    fi
    
    local backups=($(ls -1t "$backup_dir"/*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        log_info "No backups found."
    else
        echo ""
        local total_size=0
        for backup in "${backups[@]}"; do
            local size=$(du -h "$backup" | cut -f1)
            local name=$(basename "$backup")
            local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat -c "%y" "$backup" | cut -d' ' -f1)
            echo "  $name"
            echo "    Size: $size | Date: $date"
            echo ""
        done
    fi
    
    read -p "  Press Enter..."
}

function delete_old_backups() {
    draw_header "DELETE OLD BACKUPS"
    
    local backup_dir="$HOME/katana_backups"
    
    if [ ! -d "$backup_dir" ]; then
        log_info "No backups found."
        read -p "  Press Enter..."
        return
    fi
    
    echo "  How many backups to keep?"
    echo "  [1] Keep 3"
    echo "  [2] Keep 5"
    echo "  [3] Keep 10"
    echo "  [B] Back"
    echo ""
    read -p "  >> SELECT: " selection
    
    local keep=3
    case $selection in
        1) keep=3 ;;
        2) keep=5 ;;
        3) keep=10 ;;
        [bB]) return ;;
        *) log_error "Invalid selection."; read -p "  Press Enter..."; return ;;
    esac
    
    local backups=($(ls -1t "$backup_dir"/*.tar.gz 2>/dev/null))
    local total=${#backups[@]}
    
    if [ $total -le $keep ]; then
        log_info "Only $total backups exist. Nothing to delete."
        read -p "  Press Enter..."
        return
    fi
    
    local delete=$((total - keep))
    log_info "Deleting $delete old backup(s)..."
    
    for ((i=keep; i<total; i++)); do
        rm -f "${backups[$i]}"
        echo "  Deleted: $(basename "${backups[$i]}")"
    done
    
    log_success "Cleanup complete!"
    read -p "  Press Enter..."
}

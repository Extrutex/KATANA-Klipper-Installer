#!/bin/bash
# ==============================================================================
# KATANA MODULE: BACKUP & RESTORE
# Complete backup and restore functionality
# Reference: https://restic.net/ | https://restic.readthedocs.io/
# ==============================================================================

RESTIC_REPO="$HOME/katana_backups_restic"
RESTIC_PASSWORD_FILE="$HOME/.katana_backup_pwd"

function run_backup_restore() {
    while true; do
        draw_header "♻️ BACKUP & RESTORE"
        echo ""
        echo "  [1] CREATE BACKUP (tar.gz)"
        echo "  [2] RESTORE FROM BACKUP (tar.gz)"
        echo "  [3] LIST BACKUPS (tar.gz)"
        echo "  [4] DELETE OLD BACKUPS (tar.gz)"
        echo ""
        echo "  --- Restic (Referenz: restic.net) ---"
        echo "  [5] Setup Restic Repository"
        echo "  [6] CREATE BACKUP (Restic)"
        echo "  [7] RESTORE FROM BACKUP (Restic)"
        echo "  [8] LIST Restic SNAPSHOTS"
        echo "  [9] PRUNE Restic Repository"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " cmd
        
        case $cmd in
            1) create_backup ;;
            2) restore_backup ;;
            3) list_backups ;;
            4) delete_old_backups ;;
            5) setup_restic ;;
            6) restic_backup ;;
            7) restic_restore ;;
            8) restic_snapshots ;;
            9) restic_prune ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

# ============================================================
# tar.gz BACKUP (existing)
# ============================================================

function create_backup() {
    draw_header "CREATE BACKUP (tar.gz)"
    
    local backup_dir="$HOME/katana_backups"
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +"%Y-%m-%d_%H-%M")
    local backup_name="katana_backup_${timestamp}"
    local backup_path="$backup_dir/${backup_name}.tar.gz"
    
    log_info "Creating backup: $backup_name"
    
    if [ ! -d "$HOME/printer_data" ]; then
        log_error "No printer_data directory found."
        read -p "  Press Enter..."
        return
    fi
    
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
    draw_header "RESTORE FROM BACKUP (tar.gz)"
    
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
            sudo systemctl stop klipper moonraker 2>/dev/null
            cd "$HOME"
            rm -rf printer_data/config printer_data/logs
            tar -xzf "$backup_file"
            chown -R $USER:$USER printer_data
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
    draw_header "AVAILABLE BACKUPS (tar.gz)"
    
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
        for backup in "${backups[@]}"; do
            local size=$(du -h "$backup" | cut -f1)
            local name=$(basename "$backup")
            echo "  $name"
            echo "    Size: $size"
            echo ""
        done
    fi
    
    read -p "  Press Enter..."
}

function delete_old_backups() {
    draw_header "DELETE OLD BACKUPS (tar.gz)"
    
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

# ============================================================
# RESTIC BACKUP (NEW - Reference: restic.net)
# ============================================================

function setup_restic() {
    draw_header "SETUP RESTIC REPOSITORY"
    echo ""
    echo "  Reference: https://restic.net/"
    echo ""
    echo "  Restic provides:"
    echo "  • Encrypted backups"
    echo "  • Deduplication"
    echo "  • Snapshot-based restore"
    echo "  • Verification"
    echo ""
    echo "  Repository location: $RESTIC_REPO"
    echo ""
    read -p "  Continue? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    # Install restic if not present
    if ! command -v restic &> /dev/null; then
        log_info "Installing restic..."
        sudo apt-get update
        sudo apt-get install -y restic
    fi
    
    # Create backup directory
    mkdir -p "$RESTIC_REPO"
    
    # Generate password if not exists
    if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
        log_info "Generating encryption password..."
        openssl rand -base64 32 > "$RESTIC_PASSWORD_FILE"
        chmod 600 "$RESTIC_PASSWORD_FILE"
        log_success "Password saved to: $RESTIC_PASSWORD_FILE"
        log_warn "SAVE THIS PASSWORD! It's required for restore!"
    fi
    
    # Initialize repository if not exists
    if [ ! -d "$RESTIC_REPO/config" ]; then
        log_info "Initializing Restic repository..."
        RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" init
        draw_success "Restic repository initialized!"
    else
        log_info "Repository already exists."
    fi
    
    echo ""
    echo "  [i] IMPORTANT: Save your password!"
    echo "      Location: $RESTIC_PASSWORD_FILE"
    echo ""
    read -p "  Press Enter..."
}

function restic_backup() {
    draw_header "CREATE BACKUP (Restic)"
    
    # Check if restic is installed
    if ! command -v restic &> /dev/null; then
        log_error "Restic not installed. Run Option 5 first."
        read -p "  Press Enter..."
        return
    fi
    
    # Check if repository exists
    if [ ! -d "$RESTIC_REPO" ]; then
        log_error "Repository not initialized. Run Option 5 first."
        read -p "  Press Enter..."
        return
    fi
    
    if [ ! -d "$HOME/printer_data" ]; then
        log_error "No printer_data directory found."
        read -p "  Press Enter..."
        return
    fi
    
    log_info "Creating Restic backup..."
    
    RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" backup \
        "$HOME/printer_data" \
        --tag "katana" \
        --tag "$(date +%Y-%m-%d)"
    
    if [ $? -eq 0 ]; then
        draw_success "Backup created!"
        
        # Show repository stats
        echo ""
        RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" stats
    else
        log_error "Backup failed!"
    fi
    
    read -p "  Press Enter..."
}

function restic_restore() {
    draw_header "RESTORE FROM BACKUP (Restic)"
    
    if ! command -v restic &> /dev/null; then
        log_error "Restic not installed."
        read -p "  Press Enter..."
        return
    fi
    
    if [ ! -d "$RESTIC_REPO" ]; then
        log_error "No Restic repository found."
        read -p "  Press Enter..."
        return
    fi
    
    # List snapshots
    echo "  Available snapshots:"
    echo ""
    
    local snapshots=$(RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" snapshots --json 2>/dev/null)
    
    if [ -z "$snapshots" ]; then
        log_error "No snapshots found."
        read -p "  Press Enter..."
        return
    fi
    
    # Parse and display snapshots
    RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" snapshots
    
    echo ""
    echo "  Enter snapshot ID to restore (or 'latest'):"
    read -p "  >> " snap_id
    
    if [ -z "$snap_id" ]; then
        log_error "No snapshot ID entered."
        read -p "  Press Enter..."
        return
    fi
    
    if [ "$snap_id" = "latest" ]; then
        snap_id="latest"
    fi
    
    log_warn "This will overwrite current printer_data!"
    echo "  Type 'YES' to confirm: "
    read -r confirm
    
    if [ "$confirm" = "YES" ]; then
        log_info "Restoring from snapshot: $snap_id"
        
        # Stop services
        sudo systemctl stop klipper moonraker 2>/dev/null
        
        # Restore
        local restore_dir=$(mktemp -d)
        RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" restore "$snap_id" --target "$restore_dir"
        
        # Move files
        rm -rf "$HOME/printer_data"
        mv "$restore_dir/home/pi/printer_data" "$HOME/" 2>/dev/null || \
            mv "$restore_dir/printer_data" "$HOME/" 2>/dev/null || \
            log_error "Could not find printer_data in restore!"
        
        rm -rf "$restore_dir"
        
        # Fix permissions
        chown -R $USER:$USER "$HOME/printer_data" 2>/dev/null
        
        # Start services
        sudo systemctl start klipper moonraker
        
        draw_success "Restore complete!"
    else
        log_info "Cancelled."
    fi
    
    read -p "  Press Enter..."
}

function restic_snapshots() {
    draw_header "LIST Restic SNAPSHOTS"
    
    if ! command -v restic &> /dev/null; then
        log_error "Restic not installed."
        read -p "  Press Enter..."
        return
    fi
    
    if [ ! -d "$RESTIC_REPO" ]; then
        log_error "No Restic repository found."
        read -p "  Press Enter..."
        return
    fi
    
    echo ""
    RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" snapshots
    echo ""
    
    read -p "  Press Enter..."
}

function restic_prune() {
    draw_header "PRUNE Restic REPOSITORY"
    echo ""
    echo "  This removes unused data and optimizes storage."
    echo "  May take a while for large repositories."
    echo ""
    read -p "  Continue? [y/N]: " yn
    
    if [[ ! "$yn" =~ ^[yY]$ ]]; then return; fi
    
    if ! command -v restic &> /dev/null; then
        log_error "Restic not installed."
        read -p "  Press Enter..."
        return
    fi
    
    log_info "Pruning repository..."
    RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE") restic -r "$RESTIC_REPO" prune
    
    if [ $? -eq 0 ]; then
        draw_success "Prune complete!"
    else
        log_error "Prune failed!"
    fi
    
    read -p "  Press Enter..."
}

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
        echo "  [1] Erstelle Voll-Backup (Config + DB)"
        echo "  [2] Zeige Backups"
        echo "  [3] GitHub Push (Config only)"
        echo ""
        echo "  [B] Back"
        echo ""
        read -p "  >> COMMAND: " ch
        
        case $ch in
            1) create_backup ;;
            2) list_backups ;;
            3) push_config_to_git ;;
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
    
    # Verify sources
    local config_dir="$HOME/printer_data/config"
    local db_dir="$HOME/printer_data/database"
    
    if [ ! -d "$config_dir" ]; then
        log_error "Config directory not found: $config_dir"
        return 1
    fi
    
    # Create ZIP
    # We zip config and database into the archive
    # Exclude heavy files like gcodes if they are in config (should not be)
    
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
    
    # Verify remote
    if git remote -v | grep -q "origin"; then
        git push || log_error "Push failed. Check SSH keys/Auth."
    else
        log_warn "No remote 'origin' configured. Committed locally only."
    fi
    
    read -p "  Press Enter..."
}

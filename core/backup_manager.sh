#!/bin/bash

function run_backup_menu() {
    while true; do
        draw_header "BACKUP MANAGER"
        echo "  1) Backup Now (Timestamped)"
        echo "  2) Restore from Backup"
        echo "  3) Setup Auto-Backup (Cron)"
        echo "  B) Back"
        read -p "  >> " ch
        
        case $ch in
            1) perform_backup ;;
            2) perform_restore ;;
            3) setup_auto_backup ;;
            [bB]) return ;;
        esac
    done
}

function perform_backup() {
    local ts=$(date +%Y%m%d_%H%M%S)
    local dest="$HOME/katana_backups/backup_$ts"
    
    mkdir -p "$dest"
    
    log_info "Backing up printer_data to $dest..."
    
    if [ -d "$HOME/printer_data" ]; then
        rsync -a --progress "$HOME/printer_data" "$dest/"
        
        # Also zip it?
        # zip -r "$dest.zip" "$dest"
        
        log_success "Backup Complete: $dest"
    else
        log_error "No printer_data found to backup."
    fi
    read -p "  Press Enter..."
}

function perform_restore() {
    log_info "Restore not fully automated to prevent accidents."
    log_info "Please manually copy files from ~/katana_backups/ to ~/printer_data/"
    read -p "  Press Enter..."
}

function setup_auto_backup() {
    log_info "Setting up Daily Backup Cron..."
    # MVP: Just echo the cron line
    local cron_job="0 4 * * * rsync -a $HOME/printer_data $HOME/katana_backups/daily_backup"
    
    echo "  [i] Add this line to 'crontab -e':"
    echo "      $cron_job"
    echo ""
    log_success "Cron command generated."
    read -p "  Press Enter..."
}

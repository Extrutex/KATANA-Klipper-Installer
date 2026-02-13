#!/bin/bash
# ==============================================================================
# KATANA MODULE: Security & Backup Menu
# Dispatcher for Hardening and The Vault
# ==============================================================================

function run_security_menu() {
    while true; do
        draw_header "SECURITY & BACKUP VAULT"
        echo "  Protect your system and data."
        echo ""
        echo "  1) System Hardening (Firewall & Log2Ram)"
        echo "  2) Create Backup (The Vault)"
        echo "  3) Restore Backup (The Vault)"
        echo "  B) Back to Main Menu"
        
        read -p "  >> SELECT OPTION: " ch
        case $ch in
            1) run_hardening_wizard ;; # Defined in security/hardening.sh
            2) vault_create ;;        # Defined in security/vault.sh
            3) vault_restore ;;       # Defined in security/vault.sh
            [bB]) return ;;
            *) log_error "Invalid Selection." ;;
        esac
    done
}

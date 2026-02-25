#!/bin/bash
# modules/security/menu.sh

function run_security_menu() {
    while true; do
        draw_header "SECURITY & BACKUP VAULT"
        echo "  Protect your system and data."
        echo ""
        echo "  ${C_NEON}[1]${NC}  System Hardening     (Firewall & Fail2Ban)"
        echo "  ${C_NEON}[2]${NC}  Create Backup        (The Vault)"
        echo "  ${C_NEON}[3]${NC}  Restore Backup       (The Vault)"
        echo ""
        echo "  [B] Back"
        echo ""
        read -r -p "  >> SELECT: " ch
        case $ch in
            1) run_hardening_wizard ;;
            2) vault_create ;;
            3) vault_restore ;;
            [bB]) return ;;
            *) log_error "Invalid Selection." ;;
        esac
    done
}


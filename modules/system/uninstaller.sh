#!/bin/bash
# ==============================================================================
# KATANA MODULE: UNINSTALLER
# Complete removal of Klipper stack
# ==============================================================================

# Four of the five menu entries below used to delete without asking anything.
# Picking [2] removed $HOME/klipper, $HOME/klippy-env AND $HOME/printer_data —
# every printer configuration on the host — on one keypress, no confirmation,
# no undo. [5] removed KATANA itself. Only [1] asked, and its prompt was
# invisible to a `read -p` audit (see full_uninstall).
#
# The gate lives in each destructive function rather than in the menu arms that
# call them, so a direct call from a script or a future dispatcher is covered
# too. Defence at the point of destruction, not at one of its callers.
_KATANA_UNINSTALL_CONFIRMED=0

# Shared gate. full_uninstall sets _KATANA_UNINSTALL_CONFIRMED=1 after taking
# its typed-token confirmation for the whole cascade, so the operator answers
# one question for one decision instead of five for the same one.
_uninstall_gate() {
    local what="$1"
    [[ "${_KATANA_UNINSTALL_CONFIRMED:-0}" == "1" ]] && return 0
    katana_confirm_destructive "  ${what} wirklich entfernen? [y/N]: " uninstall
}

function run_uninstaller() {
    while true; do
        draw_header "KATANA UNINSTALLER"
        echo ""
        echo "  ⚠️  WARNING: This will remove ALL Klipper-related services!"
        echo ""
        echo "  [1] FULL UNINSTALL (Klipper + Moonraker + Nginx + WebUI)"
        echo "  [2] UNINSTALL KLIPPER ONLY"
        echo "  [3] UNINSTALL MOONRAKER ONLY"
        echo "  [4] UNINSTALL WEBUI (Mainsail/Fluidd)"
        echo "  [5] REMOVE ALL KATANA FILES"
        echo "  [B] Back"
        echo ""
        katana_read_menu cmd "  >> COMMAND: " "UNINSTALLER" || return
        
        case $cmd in
            1) full_uninstall ;;
            2) uninstall_klipper ;;
            3) uninstall_moonraker ;;
            4) uninstall_webui ;;
            5) remove_katana_files ;;
            [bB]) return ;;
            *) log_error "Invalid selection." ;;
        esac
    done
}

function full_uninstall() {
    log_warn "This will remove EVERYTHING. Are you sure?"
    # The most destructive path in the repository, and its confirmation was
    # invisible to any audit that greps for `read -p`: the prompt was an echo
    # and the read was bare. Unattended it failed instantly, $confirm stayed
    # empty, the != "YES" test held and the uninstall was cancelled — correct
    # by accident, for the wrong reason, and one refactor away from wiping a
    # host. It is now an explicit destructive gate.
    if ! katana_confirm_destructive "  Type 'YES' to confirm: " uninstall "YES"; then
        log_info "Cancelled."
        return 1
    fi

    # Consent for the whole cascade, taken once, above. Reset in a trap so an
    # aborted run cannot leave the rest of the session pre-authorised.
    _KATANA_UNINSTALL_CONFIRMED=1
    trap '_KATANA_UNINSTALL_CONFIRMED=0' RETURN

    log_info "Stopping all services..."
    sudo systemctl stop klipper moonraker 2>/dev/null

    uninstall_webui
    uninstall_nginx
    uninstall_moonraker
    uninstall_klipper

    log_success "Full uninstall complete."
    katana_pause "  Press Enter..."
}

function uninstall_klipper() {
    # Deletes printer_data, i.e. every printer configuration on this host.
    _uninstall_gate "Klipper, klippy-env und printer_data" || return 1
    log_info "Uninstalling Klipper..."

    # Stop and disable service
    sudo systemctl stop klipper 2>/dev/null
    sudo systemctl disable klipper 2>/dev/null
    sudo rm -f /etc/systemd/system/klipper.service
    sudo systemctl daemon-reload
    
    # Remove files
    rm -rf "$HOME/klipper"
    rm -rf "$HOME/klippy-env"
    rm -rf "$HOME/printer_data"
    
    log_success "Klipper uninstalled."
    katana_pause "  Press Enter..."
}

function uninstall_moonraker() {
    _uninstall_gate "Moonraker" || return 1
    log_info "Uninstalling Moonraker..."
    
    # Stop and disable service
    sudo systemctl stop moonraker 2>/dev/null
    sudo systemctl disable moonraker 2>/dev/null
    sudo rm -f /etc/systemd/system/moonraker.service
    sudo systemctl daemon-reload
    
    # Remove files
    rm -rf "$HOME/moonraker"
    rm -rf "$HOME/.moonraker"
    
    log_success "Moonraker uninstalled."
    katana_pause "  Press Enter..."
}

function uninstall_webui() {
    _uninstall_gate "Mainsail/Fluidd/HORIZON und die Nginx-Vhosts" || return 1
    log_info "Uninstalling WebUI..."
    
    # Stop Nginx
    sudo systemctl stop nginx 2>/dev/null
    
    # Remove Mainsail
    rm -rf "$HOME/mainsail"
    
    # Remove Fluidd
    rm -rf "$HOME/fluidd"
    
    # Remove HORIZON
    rm -rf "$HOME/horizon"
    
    # Remove Nginx config
    sudo rm -f /etc/nginx/sites-enabled/katana
    sudo rm -f /etc/nginx/sites-enabled/mainsail
    sudo rm -f /etc/nginx/sites-enabled/fluidd
    sudo rm -f /etc/nginx/sites-available/katana
    sudo rm -f /etc/nginx/sites-available/mainsail
    sudo rm -f /etc/nginx/sites-available/fluidd
    
    sudo systemctl restart nginx 2>/dev/null
    
    log_success "WebUI uninstalled."
    katana_pause "  Press Enter..."
}

function uninstall_nginx() {
    # apt-get remove nginx affects services beyond Klipper on a shared host.
    _uninstall_gate "Nginx (systemweites Paket)" || return 1
    log_info "Uninstalling Nginx..."
    
    sudo systemctl stop nginx 2>/dev/null
    sudo apt-get remove -y nginx nginx-light nginx-full 2>/dev/null
    sudo apt-get autoremove -y 2>/dev/null
    
    log_success "Nginx uninstalled."
}

function remove_katana_files() {
    # Safety check first, then the gate: the gate's message names KATANA_ROOT,
    # and asking the operator to confirm deletion of a path that is empty or
    # equal to $HOME is worse than not asking at all.
    if [ -z "${KATANA_ROOT:-}" ] || [ "$KATANA_ROOT" == "$HOME" ]; then
         log_error "Safety Stop: KATANA_ROOT is set to HOME or empty. Aborting deletion."
         return 1
    fi

    # Deletes KATANA itself, including the script currently executing.
    _uninstall_gate "KATANA selbst ($KATANA_ROOT)" || return 1
    log_info "Removing all KATANA files..."

    rm -rf "$KATANA_ROOT"
    rm -rf "$HOME/katana_diagnostics"
    rm -f "$HOME/katana.log"
    
    # Remove from PATH if added
    sed -i '/katanaos.sh/d' "$HOME/.bashrc" 2>/dev/null
    
    log_success "KATANA files removed."
    katana_pause "  Press Enter..."
}

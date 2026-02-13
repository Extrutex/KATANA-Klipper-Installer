#!/bin/bash
# ==============================================================================
# KATANA MODULE: Happy Hare (MMU)
# Wrapper for Moggieuk's Happy Hare Installer
# ==============================================================================

function install_happy_hare() {
    draw_header "HAPPY HARE (MMU)"
    echo "  This module installs the Happy Hare MMU software."
    echo "  It is compatible with ERCF, Tridex, and other MMU systems."
    echo ""
    echo "  [!] This installer runs INTERACTIVELY."
    echo "  [!] Follow the on-screen prompts from the official installer."
    echo ""
    read -p "  Press [Enter] to start (or Ctrl+C to abort)..."

    # 1. Prepare Directory
    local install_dir="$HOME/Happy-Hare"
    
    if [ -d "$install_dir" ]; then
        log_info "Happy Hare directory already exists. Updating..."
        cd "$install_dir" || return
        git pull
    else
        log_info "Cloning Happy Hare repository..."
        git clone https://github.com/moggieuk/Happy-Hare.git "$install_dir"
        cd "$install_dir" || return
    fi

    # 2. Run Installer
    log_info "Launching Official Installer..."
    echo ""
    
    # We run it directly. The user interacts with it.
    ./install.sh -i

    # 3. Post-Install Check
    if [ $? -eq 0 ]; then
        log_success "Happy Hare installation sequence finished."
        echo "  [i] Please verify your 'mmu_parameters.cfg' is linked correctly."
    else
        log_error "Happy Hare installer returned an error."
    fi

    read -p "  Press [Enter] to return to KATANA..."
}
